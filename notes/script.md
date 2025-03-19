### Install Docker

```
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io

docker --version

docker ps # fails

sudo groupadd docker
sudo usermod -aG docker $USER

sudo su ubuntu # Reload creds

docker ps # Success
```

### Run jellyfin

```bash
cd jedai/jelly

docker search jellyfin

docker pull jellyfin/jellyfin

docker run \
 --name jellyfin \
 -p 8096:8096 \
 -v $(pwd)/config:/config \
 -v $(pwd)/cache:/cache \
 --mount type=bind,source=$(pwd)/media,target=/media \
 jellyfin/jellyfin
```

Open http://localhost:8096.

### Fooocus on tailscale

```bash
curl localhost:7865
```

```bash
sudo su ubuntu
cd 
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Tailscale in a container

```json
	"tagOwners": {
		"tag:container": ["homelab@aprender.cloud"],
	},
```

```bash
KEY=...
HOST=jellyfin

sudo docker run -d \
 --name=$HOST \
 -v $(pwd)/config:/config \
 -v $(pwd)/cache:/cache \
 --mount type=bind,source=$(pwd)/media,target=/media \
 -v /var/lib/tailscale$HOST:/var/lib/tailscale \
 -v /dev/net/tun:/dev/net/tun \
 --device /dev/net/tun:/dev/net/tun \
 -e TS_STATE_DIR=/var/lib/tailscale \
 -e TS_USERSPACE=0 \
 -e TS_AUTH_ONCE=1 \
 -e TS_ACCEPT_DNS=1 \
 -e TS_HOSTNAME=$HOST \
 --cap-add=NET_ADMIN \
 --cap-add=NET_RAW \
 --env TS_AUTHKEY=$KEY \
 jellyfin/jellyfin

docker logs jellyfin

docker exec -it pokemon$NUMBER bash 
```

# in container

apt update && apt install curl git -y

curl -fsSL https://tailscale.com/install.sh | sh

tailscaled > /tailscaled.log 2>&1 &

tailscale up --authkey=$TS_AUTHKEY --hostname=$TS_HOSTNAME

## Private https access

tailscale serve 80


## Public access

Add tailscale configuration:

	"nodeAttrs": [
		{
			"target": ["tag:container"],
			"attr":   ["funnel"],
		},
	],

tailscale funnel 80

## visit the https link (it may take a few seconds the first time)
https://pokemon5.cetacean-lake.ts.net/

## Edit the ACL

	// Define users and devices that can use Tailscale SSH.
	"ssh": [
		{
			"action": "accept",
			"src":    ["homelab@aprender.cloud"],
			"dst":    ["tag:container"],
			"users":  ["ubuntu", "ec2-user", "javi", "root"],
		},
	],


tailscale up --hostname=$TS_HOSTNAME --ssh


# From your laptop, in the network

ssh root@jellyfin

