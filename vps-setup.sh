#/bin/bash

set -e

# Read domain input
read -ep "Enter your domain:"$'\n' input_domain

# Check if script started as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check congestion protocol
if sysctl net.ipv4.tcp_congestion_control | grep bbr; then
    echo "BBR is already used"
else
    if sysctl net.ipv4.tcp_available_congestion_control | grep bbr; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
    else
        echo "Seems like current kernel doesn't support BBR, please update"
    fi
fi

# Install Caddy
apt-get update
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl idn
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# Install XRay
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Generate values for XRay
export VLESS_DOMAIN=$(echo $input_domain | idn)
export XRAY_PIK=$(xray x25519 | head -n1 | cut -d' ' -f 3)
export XRAY_PBK=$(xray x25519 -i $XRAY_PIK | tail -1 | cut -d' ' -f 3)
export XRAY_SID=$(openssl rand -hex 8)
export XRAY_UUID=$(xray uuid)

# Setup config for Caddy and XRay
wget -qO- https://raw.githubusercontent.com/Akiyamov/xray-vps-setup/refs/heads/main/templates_for_script/caddy | envsubst > /etc/caddy/Caddyfile
wget -qO- https://raw.githubusercontent.com/Akiyamov/xray-vps-setup/refs/heads/main/templates_for_script/xray | envsubst > /usr/local/etc/xray/config.json

# Restart XRay and Caddy
systemctl restart xray
systemctl restart caddy

# Prettyprint outbound and clipboard string
echo "Clipboard string format"
echo "vless://$XRAY_UUID@$VLESS_DOMAIN:443?type=tcp&security=reality&pbk=$XRAY_PBK&fp=chrome&sni=$VLESS_DOMAIN&sid=$XRAY_SID&spx=%2F&flow=xtls-rprx-vision" | envsubst
echo "XRay outbound config"
wget -qO- https://raw.githubusercontent.com/Akiyamov/xray-vps-setup/refs/heads/main/templates_for_script/xray_outbound | envsubst 
echo "Sing-box outbound config"
wget -qO- https://raw.githubusercontent.com/Akiyamov/xray-vps-setup/refs/heads/main/templates_for_script/sing_box_outbound | envsubst 
echo "Plain data"
echo "PBK: $XRAY_PBK, SID: $XRAY_SID, UUID: $XRAY_UUID"