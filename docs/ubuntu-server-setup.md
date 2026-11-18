# 9. Setting Up Docker on Ubuntu Server (VirtualBox)

These steps follow the official Docker Engine installation method for Ubuntu using Docker's `apt` repository. They work on Ubuntu Server (no desktop needed), including inside a VirtualBox virtual machine.

## Requirements
- A supported, 64-bit Ubuntu release (see "Install Docker Engine on Ubuntu" in the official docs for the current list).
- A user with `sudo` rights.
- Internet access from the VM.

## 1. Remove conflicting packages (only if they are installed)
```bash
sudo apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc
```
It is fine if apt reports that some of them are not installed.

## 2. Add Docker's official apt repository
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

## 3. Install Docker Engine, Buildx and Compose
```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
The Docker service starts automatically on Ubuntu.

## 4. Verify
```bash
sudo systemctl status docker --no-pager
sudo docker run --rm hello-world
docker compose version
```

## 5. Run Docker without `sudo` (recommended)
```bash
sudo usermod -aG docker $USER
```
Then **log out and log in again** (or run `newgrp docker` in the current shell) and test:
```bash
docker run --rm hello-world
```
Members of the `docker` group can control the Docker daemon, which is equivalent to having root access on the machine, so add only users you trust.

## 6. Start Docker automatically at boot (normally already enabled)
```bash
sudo systemctl enable docker
```

## Reaching a container from your host computer (VirtualBox)
Containers listen inside the VM. To open them in a browser on your host computer, use one of these options.

**Option A - NAT port forwarding (works with the default NAT adapter)**
1. Shut down the VM (or use the VirtualBox settings while it is running).
2. In VirtualBox select the VM, then **Settings → Network → Adapter 1 → Advanced → Port Forwarding**.
3. Add a rule: Protocol `TCP`, Host Port `5000`, Guest Port `5000` (leave the IP fields empty). Repeat for other ports such as `8080` and `8081`.
4. On the host open `http://localhost:5000`.

**Option B - Bridged adapter**
Set the adapter to **Bridged Adapter**. The VM then gets an address on your local network. Find it inside the VM with `ip addr` and open `http://VM_IP:5000` from the host.

If you only test with `curl` inside the VM, you do not need either option.

## Troubleshooting
| Problem | Fix |
|---------|-----|
| `permission denied while trying to connect to the Docker daemon socket` | Use `sudo`, or complete step 5 and log in again |
| `Cannot connect to the Docker daemon` | `sudo systemctl start docker` |
| `port is already allocated` or `address already in use` | Another program or container uses that port; stop it or change the host port in `-p HOST:CONTAINER` |
| `docker compose: command not found` | Install `docker-compose-plugin` (step 3); the command is `docker compose` (with a space) |
| Pulls fail or time out | Check the VM's internet connection and DNS: `ping -c 2 hub.docker.com` |
| Disk space running low | `docker system df`, then `docker system prune` |

## Source
Docker documentation: "Install Docker Engine on Ubuntu" (https://docs.docker.com/engine/install/ubuntu/) and "Linux post-installation steps for Docker Engine" (https://docs.docker.com/engine/install/linux-postinstall/).
