#!/bin/bash
# WireGuard VPN Setup Script

# Exit on error
set -e

# Set default values
SERVER_IP=$(curl -s https://ipinfo.io/ip)
WIREGUARD_PORT=51820
WIREGUARD_NETWORK="10.8.0.0/24"
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)
DNS_SERVERS="1.1.1.1, 8.8.8.8"

# Create WireGuard config directory if it doesn't exist
mkdir -p /etc/wireguard

# Create server configuration
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = ${WIREGUARD_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = 10.8.0.2/32
EOF

# Enable and start WireGuard service
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Create client configuration
mkdir -p /root/wireguard-clients
cat > /root/wireguard-clients/client.conf << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = 10.8.0.2/24
DNS = ${DNS_SERVERS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${SERVER_IP}:${WIREGUARD_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

echo "WireGuard VPN has been set up successfully!"
echo "Server configuration is in /etc/wireguard/wg0.conf"
echo "Client configuration is in /root/wireguard-clients/client.conf"
echo "Use the client configuration on your device to connect to the VPN."
