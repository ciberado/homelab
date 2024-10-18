# Running Ollama on EC2

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

## Ollama setup

Who said fear?

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Now install and run at least one model:

```bash
ollama pull phi3
ollama run phi3
```

## Testing

We will need `jq` for playing with the JSON response:

```bash
sudo apt install -y jq
```

Now check that the Ollama API is working (use this prompt at your own risk):

```bash
curl -s http://localhost:11434/api/generate -d '{
  "model": "phi3",
  "prompt": "Tell me a joke.", 
  "stream" : false
}' | jq .response
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
sudo tailscale up --hostname ollama
```

Now it should be available in your tailnet, on port 11434.

