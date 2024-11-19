# Triviaten

This cookbook setups my fork of [Trivia-ten](https://github.com/Jeusto/trivia-ten). It is intended 
to be an example of how to run a virtual device with docker compose exposed to the
public internet.

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
SERVICE_NAME=triviaten
IMAGE=node:alpine
PORT=3000
```

Make a directory for the service:

```bash
mkdir $SERVICE_NAME
cd $SERVICE_NAME
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
    "${TS_CERT_DOMAIN}:443": true
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
  ${SERVICE_NAME}:
    container_name: ${SERVICE_NAME}
    image: node:alpine
    depends_on:
      - ts-${SERVICE_NAME}
    network_mode: service:ts-${SERVICE_NAME}
    volumes:
      - /mnt/d/vscode/projects/trivia-ten/:/app
    restart: unless-stopped
    command: sh -c "cd /app; PORT=3000 npm run dev"

  ts-${SERVICE_NAME}:
    image: tailscale/tailscale:latest
    hostname: ts-${SERVICE_NAME}
    environment:
      - TS_AUTHKEY=tskey-client-k7wpGAsarZ11CNTRL-tdtXyPzjpSKdiBZ3ALLbTK2NJ4tBzj5Zd
      - TS_EXTRA_ARGS=--advertise-tags=tag:container
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_SERVE_CONFIG=/config/${SERVICE_NAME}.json
    volumes:
      - tailscale-data-${SERVICE_NAME}:/var/lib/tailscale
      - ./ts-${SERVICE_NAME}/config:/config
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - net_admin
      - sys_module
    restart: unless-stopped

volumes:
  tailscale-data-${SERVICE_NAME}:
    driver: local
EOF
```

Great. Now start the services in the background:

```bash
docker compose up -d
```

Your instance should be up and running, and accessible from the internet:

```bash
echo Open https://${SERVICE_NAME}.${NET_NAME}.ts.net
```
