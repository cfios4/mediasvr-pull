#!/bin/bash

# Get OS
os=$(uname -s)

# Function to install packages using the detected package manager
install_packages() {
    if [ -x "$(command -v apt)" ]; then
        sudo apt update -y
        sudo apt install -y "$@"
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf update -y
        sudo dnf install -y "$@"
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Syu
        sudo pacman -S --noconfirm "$@"
    elif [ -x "$(command -v pkg)" ]; then
        sudo pkg update -y
        sudo pkg install -y "$@"
    else
        echo "Unsupported package manager"
        exit 1
    fi
}

# Install packages based on the detected operating system
case "$os" in
    Linux*) install_packages ansible git ;;
    *) echo "Unsupported operating system" ; exit 1 ;;
esac

# Install Docker and Tailscale
curl -fsSL https://get.docker.com/ | bash
curl -fsSL https://tailscale.com/install.sh | bash
systemctl enable docker --now
systemctl enable tailscaled --now

# Set $RESU variable
if [ -z "$RESU" ]; then
    if [ -f "/tmp/RESU_exist" ]; then
        return 0
    else
        # Variable is empty, ask for input
        clear
        read -p "Enter new local Docker user's name: " RESU
        touch /tmp/RESU_exist
    fi
# Test if $TS_API is defined
elif [ -z "$TS_API" ]; then
    if [ -f "/tmp/TSAPI_exist" ]; then
        return 0
    else
        # Variable is empty, ask for input
        clear
        read -p "Please enter Tailscale API key: " TS_API
        touch /tmp/TSAPI_exist
    fi
fi

# Check if $TS_KEY and $RESU are set
if [ -n "$RESU" ] && [ -n "$TS_API" ] ; then
    # Join Tailnet
    export TS_KEY=$(curl -s -H "Authorization: Bearer $TS_API" -d '{"capabilities":{"devices":{"create":{"reusable":false,"ephemeral":false,"preauthorized":true}}}}' https://api.tailscale.com/api/v2/tailnet/-/keys | grep -o '"key":"[^"]*"' | sed 's/"key":"\(.*\)"/\1/')
    tailscale up --auth-key=$TS_KEY --operator $RESU --ssh
fi

# Set UID 1000 to $RESU
useradd -m -G wheel,docker -u 1000 $RESU
passwd -e $RESU > /dev/null

# Create directories for app bind mounts
mkdir -p /home/$RESU/swarmConfigs/appdata/{caddy/serve,flame,plex,radarr,sonarr,sabnzbd,vscode}

# Set $TAILSCALEIP
echo $(tailscale ip -4) >> /home/$RESU/.bashrc

# Initialize Swarm
docker swarm init --advertise-addr $TAILSCALEIP > /dev/null

# Ansible pull repo
ansible-pull -U https://github.com/cfios4/mediasvr-pull.git -d /home/$RESU/
