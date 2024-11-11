# Miniflux RSS reader

Miniflux is a simple, opinionated and powerful RSS reader.

## Prerequisites

* A recent version of docker.
* An available tailnet in place.
* If you are running Windows, a WSL session attached to the Tailnet.

## General preparation

First, generate an OAuth token for the service. The process is shown in [this video](https://youtu.be/5eqXgkTZkpo).

```bash
OAUTH_CLIENT_SECRET=<The generated token>
```

Set the name of your tailnet in another variable:

```bash
NET_NAME=<your tailnet name, something like winki-pinki>
```

Define the rest of the parameters:

```bash
SERVICE_NAME=miniflux
IMAGE=miniflux/miniflux:latest
PORT=8080
```

Make a directory for the service:

```bash
mkdir $SERVICE_NAME
cd $SERVICE_NAME
```

## Nginx configuration

Although it would probably be more practical using `tailnet funnel`, I
setup TLS using a `nginx` server with its own configuration, mostly because
I'm familiar with it and I may want to implement additional controls
in the future..

First, let's create directory for the configuration:

```bash
mkdir -p nginx/conf
```

Now write the configuration. See how the `ssl_certificate` and
`ssl_certificate_key` files are named using Tailscale's convention.

```nginx
cat << EOF > nginx/conf/nginx.conf
server {
    listen 80;

    server_name ${SERVICE_NAME};
    client_max_body_size 300M;

    location / {
        proxy_pass http://${SERVICE_NAME}_server:$PORT;
        add_header  X-Upstream  \$upstream_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen              443 ssl;
    server_name         ${SERVICE_NAME}.${NET_NAME}.ts.net;
    client_max_body_size 300M;

    ssl_certificate     /etc/nginx/conf.d/${SERVICE_NAME}.${NET_NAME}.ts.net.crt;
    ssl_certificate_key /etc/nginx/conf.d/${SERVICE_NAME}.${NET_NAME}.ts.net.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://${SERVICE_NAME}_server:$PORT;
        add_header  X-Upstream  \$upstream_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
```

## Tailscale sidecar configuration

The network sidecar is configured using a simple *JSON* file. In this
case we want to accept public traffic (see the `AllowFunnel` property)
and automatically manage TLS.

Let's create a directory for the configuration:

```bash
mkdir -p ts-${SERVICE_NAME}/config
```

And then, write the conf file:

```json
cat << 'EOF' >> ts-${SERVICE_NAME}/config/${SERVICE_NAME}.json
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": {
          "Proxy": "http://127.0.0.1"
        }
      }
    }
  },
  "AllowFunnel": {
    "${TS_CERT_DOMAIN}:443": false
  }
}
EOF
```

## Docker compose services definition

Write the compose file. The most interesting part is how we
instruct the Tailscale sidecar container (`ts-${SERVICE_NAME}`)
for using the configuration previously created:

```yaml
cat << EOF > docker-compose.yml
services:
  ${SERVICE_NAME}-server:
    container_name: ${SERVICE_NAME}_server
    image: ${IMAGE}
    depends_on:
      - ts-${SERVICE_NAME}
      - db
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgres://miniflux:minifluxsecret@db/miniflux?sslmode=disable
      - RUN_MIGRATIONS=1
      - CREATE_ADMIN=1
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=minifluxadmin

  db:
    image: postgres:17-alpine
    environment:
      - POSTGRES_USER=miniflux
      - POSTGRES_PASSWORD=minifluxsecret
      - POSTGRES_DB=miniflux
    volumes:
      - miniflux-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "miniflux"]
      interval: 10s
      start_period: 30s

  ts-${SERVICE_NAME}:
    image: tailscale/tailscale:latest
    hostname: ${SERVICE_NAME}
    environment:
      - TS_AUTHKEY=$OAUTH_CLIENT_SECRET
      - TS_EXTRA_ARGS=--advertise-tags=tag:container
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_SERVE_CONFIG=/config/${SERVICE_NAME}.json
    volumes:
      - tailscale-data-${SERVICE_NAME}:/var/lib/tailscale
      - ${PWD}/ts-${SERVICE_NAME}/config:/config
      - /dev/net/tun:/dev/net/tun
      - ./nginx/conf/:/certs
    cap_add:
      - net_admin
      - sys_module
    restart: unless-stopped
  ${SERVICE_NAME}:
    image: nginx
    network_mode: service:ts-${SERVICE_NAME}
    depends_on:
      - ts-${SERVICE_NAME}
    restart: unless-stopped
    volumes:
      - ./nginx/conf/:/etc/nginx/conf.d/:ro

volumes:
  tailscale-data-${SERVICE_NAME}:
    driver: local
  miniflux-db:
EOF
```

Great. Now start the services in the background:

```bash
docker compose up -d
```

Jump into the Tailscale sidecar container and use it for generating
the expected TLS certificate in the directory shared with Nginx:

```bash
docker compose exec ts-${SERVICE_NAME} \
  sh -c "cd certs; tailscale cert ${SERVICE_NAME}.${NET_NAME}.ts.net"
```

Your Miniflux instance should be up and running in your tailnet:

```bash
echo Open https://${SERVICE_NAME}.${NET_NAME}.ts.net
```
