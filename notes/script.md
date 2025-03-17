sudo su ubuntu
cd 
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

------------------

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

--------------------

docker run --name pokemon -d -p 80:80 ciberado/pokemon-nodejs:1.0.3

tailscale ip -4

IP=$(tailscale ip -4)
echo Open http://$IP

--------------------------

Set the new tag in the acl:

{
	...
	
	"tagOwners": {
		"tag:container": ["homelab@aprender.cloud"]
	},
	
	...
}


# In ubuntu
apt update && apt install curl -y
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up

sudo docker run -d --name=tailscaled --restart=always \
	-v /var/lib/tailscale1:/var/lib/tailscale \
	-v /var/lib:/var/lib \
	-v /dev/net/tun:/dev/net/tun \
	--device /dev/net/tun:/dev/net/tun \
	-e TS_STATE_DIR=/var/lib/tailscale \
	-e TS_USERSPACE=0 \
	-e TS_AUTH_ONCE=1 \
	-e TS_ACCEPT_DNS=1 \
	-e TS_HOSTNAME=pokemon \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	--env TS_AUTHKEY=tskey-auth-ktDd6atBBB21CNTRL-pQ7pyHFJvNSV9kQt53WZNSDLxnnwgA9WJ \
	tailscale/tailscale:stable

# check the admin page
# see the new node

# Inside the container

mkdir web && cd web
wget https://pastebin.com/raw/kAQg0yhu -O index.html
sed -i "s/<h2>.*<\/h2>/<h2>Pikachu from $TS_HOSTNAME<\/h2>/g" index.html

apk add caddy
caddy file-server &


# generate new key

sudo docker run -d --name=pokemon2 --restart=always \
	-v /var/lib/tailscale2:/var/lib/tailscale \
	-v /var/lib:/var/lib \
	-v /dev/net/tun:/dev/net/tun \
	--device /dev/net/tun:/dev/net/tun \
	-e TS_STATE_DIR=/var/lib/tailscale \
	-e TS_USERSPACE=0 \
	-e TS_AUTH_ONCE=1 \
	-e TS_ACCEPT_DNS=1 \
	-e TS_HOSTNAME=pokemon2 \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	--env TS_AUTHKEY=tskey-auth-kn4qiEkJGD21CNTRL-dMTNQjwHDUja9MxwtR5yTjCZSzkykKpf \
	tailscale/tailscale:stable

docker exec -it pokemon2 sh

# check the admin page
# see the new node

# Inside the container

mkdir web && cd web
wget https://pastebin.com/raw/kAQg0yhu -O index.html
sed -i "s/<h2>.*<\/h2>/<h2>Pikachu from $TS_HOSTNAME<\/h2>/g" index.html

apk add caddy
caddy file-server &


# generate new key


sudo docker run -d --name=pokemon4 --restart=always \
	-v /var/lib/tailscale4:/var/lib/tailscale \
	-v /var/lib:/var/lib \
	-v /dev/net/tun:/dev/net/tun \
	--device /dev/net/tun:/dev/net/tun \
	-e TS_STATE_DIR=/var/lib/tailscale \
	-e TS_USERSPACE=0 \
	-e TS_AUTH_ONCE=1 \
	-e TS_ACCEPT_DNS=1 \
	-e TS_HOSTNAME=pokemon4 \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	--env TS_AUTHKEY=tskey-auth-kqpKQs7Q4c11CNTRL-kuYCCXzCyJZ1ebzvujogJZmPA6b2ia4y \
	ciberado/pokemon-nodejs:1.0.3
	
docker exec -it pokemon4 sh

muévelo a node:ubuntu 

# in pokemon 3

wget -qO- localhost

wget -qO- https://tailscale.com/install.sh | sh

tailscaled > /tailscaled.log 2>&1 &


tailscale up --authkey=$TS_AUTHKEY --hostname=$TS_HOSTNAME



---------------------------------

NUMBER=5
sudo docker run -d --name=pokemon$NUMBER --restart=always \
	-v /var/lib/tailscale$NUMBER:/var/lib/tailscale \
	-v /dev/net/tun:/dev/net/tun \
	--device /dev/net/tun:/dev/net/tun \
	-e TS_STATE_DIR=/var/lib/tailscale \
	-e TS_USERSPACE=0 \
	-e TS_AUTH_ONCE=1 \
	-e TS_ACCEPT_DNS=1 \
	-e TS_HOSTNAME=pokemon$NUMBER \
	--cap-add=NET_ADMIN \
	--cap-add=NET_RAW \
	--env TS_AUTHKEY=tskey-auth-kiYNNGbngD11CNTRL-rUF2P6gEk2XZE1ERUyPP2XZABmHiTwt5H \
	node:slim bash -c "sleep 100000"

docker exec -it pokemon$NUMBER bash 

# in container

apt update && apt install curl git -y

curl -fsSL https://tailscale.com/install.sh | sh
tailscaled > /tailscaled.log 2>&1 &
tailscale up --authkey=$TS_AUTHKEY --hostname=$TS_HOSTNAME


git clone https://github.com/ciberado/pokemon-nodejs
cd pokemon-nodejs
npm i 
npm run start &

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

ssh root@pokemon5

