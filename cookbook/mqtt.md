# MQTT with Mosquitto

## Prerequisites

* A recent version of docker.
* An available tailnet in place.
* If you are running Windows, a WSL session attached to the Tailnet.

## Mosquitto preparation

First, generate an OAuth token for the service. The process is shown in [this video](https://youtu.be/5eqXgkTZkpo).

```bash
OAUTH_CLIENT_SECRET=<The generated token>
```

Set the name of your tailnet in another variable:

```bash
NET_NAME=<your tailnet name, something like winki-pinki>
```

Choose an username and password for your Mosquitto server:

```bash
MQTT_USER=<your username>
MQTT_PASS=<your very secret password>
```

Define the rest of the parameters:

```bash
SERVICE_NAME=mqtt
IMAGE=eclipse-mosquitto
PORT=1883
```

Make a directory for the service:

```bash
mkdir $SERVICE_NAME
cd $SERVICE_NAME
```

Mosquitto requires a specific configuration. We will write it in the `config` directory:

```bash
mkdir config

cat << EOF > config/mosquitto.conf 
allow_anonymous false
listener 1883
listener 9001
protocol websockets
persistence true
password_file /mosquitto/config/pwfile
persistence_file mosquitto.db
persistence_location /mosquitto/data/
EOF
```

Use the `docker` client for setting the authentication identity.

```bash
docker run --rm -v $(pwd)/config:/mosquitto/config/ \
  $IMAGE \
  sh -c "mosquitto_passwd -b -c /mosquitto/config/pwfile $MQTT_USER $MQTT_PASS"
```

## Docker compose services definition

Write the compose file:

```bash
cat << EOF > docker-compose.yml
services:
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
    image: eclipse-mosquitto
    network_mode: service:ts-${SERVICE_NAME}
    depends_on:
      - ts-${SERVICE_NAME}
    volumes:
      - ./config:/mosquitto/config:rw
      - ./data:/mosquitto/data:rw
      - ./log:/mosquitto/log:rw
    restart: unless-stopped
volumes:
  config:
  data:
  log:
  tailscale-data-${SERVICE_NAME}:
    driver: local
EOF
```

And now start it all in the background:

```bash
docker compose up -d
```

## Testing

Check the logs to see if anything failed on the Tailscale sidecar or the
mosquitto container itself:

```bash
docker compose logs ts-${SERVICE_NAME}
docker compose logs ${SERVICE_NAME}
```

Use the `docker` command for subscribing to the general topic and see

```bash
docker run \
  --name mqtttest-sub \
  -d \
  efrecon/mqtt-client \
  sh -c "mosquitto_sub -h mqtt -t '#' -v -u $MQTT_USER -P '$MQTT_PASS' -i testclient"
```

Run another container to put a message on the queue:

```bash
docker run --rm \
  efrecon/mqtt-client \
  sh -c "mosquitto_pub -h mqtt -t 'test/one' -m 'Hi.' -u $MQTT_USER -P '$MQTT_PASS' -i testprod"
```

And check if the message is being delivered:

```bash
docker logs mqtttest-sub
```

Finish the subscription container:

```bash
docker stop mqtttest-sub
docker rm mqtttest-sub
```

## Windows-WSL network bridge

If you are using WSL under Windows 10/11, the MQTT port is not available
out of the host machine, so the IoT things you have around your home
will not be able to reach it. 

Usually we would solve this problem by setting our HomeLab instance as
a subnet router, but I haven't managed to make it work from WSL. So instead,
we can solve it by forwarding traffic between Windows and 
the WSL virtual machine.

**BEWARE: The following commands must be run from an administration
session with powershell**.

First, get the IP address of the virtual machine (if you have several distributions running at the same time, it would be better to manually assign it).

```powershell
$wslIpList=wsl hostname -I
$wslFirstIp, $b, $c = $wslIpList -split " ",2

echo "The WSL IP is $wslFirstIp."
```


```powershell
netsh interface portproxy `
  add v4tov4 `
  listenport=1883 `
  listenaddress=0.0.0.0 `
  connectport=1883 `
  connectaddress=$wslFirstIp
```

Ok, enough powershell. **Go back to your WSL session of your HomeLab instance**.

Now the traffic from the home network reaches the WSL session, but we need to forward it to the MQTT device. At the moment, I'm doing it with [simpleproxy](https://manpages.ubuntu.com/manpages/trusty/man1/simpleproxy.1.html):

```bash
apt install simpleproxy -y
simpleproxy -L 1883 -R mqtt:1883 -d
```

Now you can use your HomeLab instance IP as a destination for those tiny IoT devices that are running in your home network but are not part of the tailnet.
