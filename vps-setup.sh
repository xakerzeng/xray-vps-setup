#/bin/bash 

set -exu

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

# Install Caddy, JQ
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl jq
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o --batch --yes /usr/share/keyrings/caddy-stable-archive-keyring.gpg 
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# Install XRay
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Generate values for XRay
XRAY_PIK=$(xray x25519 | head -n1 | cut -d' ' -f 3)
XRAY_PBK=$(xray x25519 -i $XRAY_PIK | tail -1 | cut -d' ' -f 3)
XRAY_SID=$(openssl rand -hex 8)
XRAY_UUID=$(xray uuid)

# Setup config for Caddy
echo "{
    https_port $VLESS_PORT
    default_bind 127.0.0.1
}
https://$VLESS_DOMAIN {
  root * /srv
  file_server browse
  log {
    output file /var/lib/caddy/access.log {
      roll_size 10mb
      roll_keep 5
    }
  }
}
http://$VLESS_DOMAIN {
  redir https://{host}{uri} permanent
}" > /etc/caddy/Caddyfile

# Setup config for XRay
echo '{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "",
        "serverNames": [
          ""
        ],
        "privateKey": "",
        "shortIds": [
          ""
        ],
        "spiderX": "/"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": [
        "http",
        "tls",
        "quic"
      ],
      "routeOnly": true
    }
  }],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}' > /usr/local/etc/xray/config.json
echo $(jq ".inbounds[0].settings.clinets[0] += { \"id\": \"$XRAY_UUID\", \"email\": \"default\", \"flow\": \"xtls-rprx-vision\" }" /usr/local/etc/xray/config.json) > /usr/local/etc/xray/config.json
echo $(jq ".inbounds[0].streamSettings += { \"realitySettings\": { \"dest\": \"127.0.0.1:$VLESS_PORT\", \"serverNames\": [ \"$VLESS_DOMAIN\" ], \"privateKey\": \"$XRAY_PIK\", \"shortIds\": [ \"$XRAY_SID\" ], \"spiderX\": \"/\" } }" /usr/local/etc/xray/config.json) > /usr/local/etc/xray/config.json
systemctl restart xray
systemctl restart caddy
echo "PBK: $XRAY_PBK, SID: $XRAY_SID, UUID: $XRAY_UUID"