# Home Assistant

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
SERVICE_NAME=ha
IMAGE=ghcr.io/home-assistant/home-assistant:stable
PORT=8123
```

Make a directory for the service:

```bash
mkdir $SERVICE_NAME
cd $SERVICE_NAME
```

## Nginx configuration

Although it would probably be more practical using `tailnet serve`, I
setup TLS using a `nginx` server with its own configuration.

First, create directory for it:

```bash
mkdir nginx/conf
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

## Docker compose services definition

Write the compose file. Pay attention to the fact that the `nginx/conf`
directory is shared between the host, the Tailscale sidecar container 
and the Nginx container.

```yaml
cat << EOF > docker-compose.yml
services:
  ${SERVICE_NAME}-server:
    container_name: ${SERVICE_NAME}_server
    image: ${IMAGE}
    depends_on:
      - ts-${SERVICE_NAME}
    restart: unless-stopped

  ts-${SERVICE_NAME}:
    image: tailscale/tailscale:latest
    hostname: ${SERVICE_NAME}
    environment:
      - TS_AUTHKEY=$OAUTH_CLIENT_SECRET
      - TS_EXTRA_ARGS=--advertise-tags=tag:container
      - TS_STATE_DIR=/var/lib/tailscale
    volumes:
      - tailscale-data-${SERVICE_NAME}:/var/lib/tailscale
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
EOF

Start the services in the background:

```bash
docker compose up -d
```

Jump into the Tailscale sidecar container and use it for generating
the expected TLS certificate in the directory shared with Nginx:

```bash
docker compose exec ts-${SERVICE_NAME} \
  sh -c "cd certs; tailscale cert ${SERVICE_NAME}.${NET_NAME}.ts.net"
```

Your HA instance should be up and running:

```bash
echo Open https://${SERVICE_NAME}.${NET_NAME}.ts.net
```
