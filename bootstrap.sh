#!/bin/bash
# Set $USER variable
read -p "Enter new local user's name: " RESU

# Set UID 1000 to $RESU
useradd -m -G wheel,docker -u 1000 $RESU
passwd -e $RESU

# Baseline stuff
dnf upgrade -y
dnf install ansible -y

# Install Docker and Tailscale
curl -fsSL https://get.docker.com/ | bash
curl -fsSL https://tailscale.com/install.sh | bash
systemctl enable docker --now
systemctl enable tailscaled --now

# Create directories for app bind mounts
mkdir -p /home/$RESU/swarmConfigs/apps/{caddy/serve,flame,plex,radarr,sonarr,sabnzbd,vscode}

# Test if $TS_KEY is defined
if [ -z "$TS_API" ]; then
    # Variable is empty, ask for input
    read -p "Please enter Tailscale API key: " TS_API
fi

# Join Tailnet
export TS_KEY=$(curl -s -H "Authorization: Bearer $TS_API" -d '{"capabilities":{"devices":{"create":{"reusable":false,"ephemeral":false,"preauthorized":true}}}}' https://api.tailscale.com/api/v2/tailnet/-/keys | grep -o '"key":"[^"]*"' | sed 's/"key":"\(.*\)"/\1/')
tailscale up --auth-key=$TS_KEY --operator $RESU --ssh

# Ansible pull repo
ansible-pull -U https://github.com/cfios4/mediasvr-pull.git -d /home/$RESU
