# Running Fooocus on EC2

## Prerequisites

* An available tailnet in place.
* An g4nd.xlarge EC2 instance running Ubuntu, with access to internet.

## GPU support

First, install the packages:

```bash
sudo apt update
sudo apt install -y ubuntu-drivers-common -y
sudo ubuntu-drivers install
```

Now reboot the instance. Yes, I know.

```bash
sudo reboot
```

Check if the drivers are working:

```bash
nvidia-smi
```

## Fooocus setup

Download the code:

```bash
git clone https://github.com/lllyasviel/Fooocus.git
cd Fooocus
```

Add the env management tool:

```bash
sudo apt install python3.12-venv -y
```

Create an environment and activate it:

```bash
python3 -m venv fooocus_env
source fooocus_env/bin/activate
```

Download the dependencies:

```bash
pip install -r requirements_versions.txt
```

## Service configuration

Setup Fooocus as a service, so it is restarted on boot. First, write
the unit description:

```ini
cat << EOF > fooocus.service
[Unit]
Description=Fooocus!
After=syslog.target
After=network.target

[Service]
ExecStart=/home/ubuntu/Fooocus/fooocus_env/bin/python /home/ubuntu/Fooocus/entry_with_update.py --listen
Type=simple
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
```

Now move it to the correct place:

```bash
sudo mv fooocus.service /etc/systemd/system/
```

Start the service and enable it for running on bootstrap:

```bash
sudo systemctl start fooocus
sudo systemctl enable fooocus
```

## Tailscale configuration

Add the repos:

```bash
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
```

Install the software:

```bash
sudo apt-get update
sudo apt-get install tailscale -y
```

Add the device (unless you provide an OAuth key, you will require to manually
authorize the device registration by following the screen instructions):

```bash
sudo tailscale up --hostname fooocus
```

Now it should be available in your tailnet, on port 7865.