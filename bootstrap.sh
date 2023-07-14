#!/bin/bash

# Get OS
OS=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')

if [ $OS = 'debian' ]; then
    apt update -y
    apt upgrade -y
    apt install ansible git -y
elif [ $OS = 'rhel centos fedora' ]; then
    dnf upgrade -y
    dnf install ansible git -y
elif [ $OS = 'alpine' ]; then
    dnf upgrade -y
    dnf install ansible git -y
else
    echo "Can't recognize operating system from /etc/os-release!"
    exit
fi

# Install Docker and Tailscale
curl -fsSL https://get.docker.com/ | bash
curl -fsSL https://tailscale.com/install.sh | bash
systemctl enable docker --now
systemctl enable tailscaled --now

# Set $RESU variable
if [ -z "$RESU" ]; then
    # Variable is empty, ask for input
    clear
    read -p "Enter new local Docker user's name: " RESU
# Test if $TS_API is defined
elif [ -z "$TS_API" ]; then
    # Variable is empty, ask for input
    clear
    read -p "Please enter Tailscale API key: " TS_API
fi

# Set UID 1000 to $RESU
useradd -m -G wheel,docker -u 1000 $RESU
passwd -e $RESU > /dev/null

# Create directories for app bind mounts
mkdir -p /home/$RESU/swarmConfigs/appdata/{caddy/serve,flame,plex,radarr,sonarr,sabnzbd,vscode}

# Join Tailnet
export TS_KEY=$(curl -s -H "Authorization: Bearer $TS_API" -d '{"capabilities":{"devices":{"create":{"reusable":false,"ephemeral":false,"preauthorized":true}}}}' https://api.tailscale.com/api/v2/tailnet/-/keys | grep -o '"key":"[^"]*"' | sed 's/"key":"\(.*\)"/\1/')
tailscale up --auth-key=$TS_KEY --operator $RESU --ssh

# Set $TAILSCALEIP
echo $(tailscale ip -4) >> /home/$RESU/.bashrc

# Initialize Swarm
docker swarm init --advertise-addr $TAILSCALEIP > /dev/null

# Ansible pull repo
ansible-pull -U https://github.com/cfios4/mediasvr-pull.git -d /home/$RESU
