#!/bin/bash
# Set UID 1000 to $RESU
useradd -m -G wheel,docker -u 1000 casey
RESU=$(getent passwd 1000 | cut -d':' -f1)

# Install Docker and Tailscale
curl -fsSL https://get.docker.com/ | bash
curl -fsSL https://tailscale.com/install.sh | bash
systemctl enable docker --now
systemctl enable tailscaled --now

# Baseline stuff
dnf upgrade -y
dnf install ansible -y

# Ansible pull repo
ansible-pull -U https://github.com/cfios4/mediasvr-pull.git -d /home/$RESU

# Create directories for app bind mounts
mkdir -p /home/$RESU/swarmConfigs/apps/{caddy,flame,plex,radarr,sonarr,sabnzbd,vscode}

# Test if $TS_KEY is defined
if [ -z "$TS_API" ]; then
    # Variable is empty, ask for input
    read -p "Please enter Tailscale API key: " TS_API
fi

# Join Tailnet
export TS_KEY=$(curl -s -H "Authorization: Bearer $TS_API" -d '{"capabilities":{"devices":{"create":{"reusable":false,"ephemeral":false,"preauthorized":true}}}}' https://api.tailscale.com/api/v2/tailnet/-/keys | grep -o '"key":"[^"]*"' | sed 's/"key":"\(.*\)"/\1/')
tailscale up --auth-key=$TS_KEY --operator $RESU --ssh\
