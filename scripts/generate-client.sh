#!/bin/bash

# Script to generate client certificates and configuration files

if [ $# -eq 0 ]; then
    echo "Usage: $0 <client-name>"
    echo "Example: $0 john-laptop"
    exit 1
fi

CLIENT_NAME=$1
EASY_RSA_DIR="/etc/openvpn/easy-rsa"
SERVER_IP=${SERVER_IP:-"YOUR_SERVER_IP"}

cd $EASY_RSA_DIR

# Source vars
source ./vars

# Generate client certificate and key
echo "Generating certificate for client: $CLIENT_NAME"
./build-key --batch $CLIENT_NAME

# Create client configuration directory
mkdir -p /tmp/openvpn-clients/$CLIENT_NAME

# Generate client configuration file
cat > /tmp/openvpn-clients/$CLIENT_NAME/$CLIENT_NAME.ovpn << EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-256-CBC
verb 3

<ca>
$(cat keys/ca.crt)
</ca>

<cert>
$(cat keys/$CLIENT_NAME.crt)
</cert>

<key>
$(cat keys/$CLIENT_NAME.key)
</key>

<tls-auth>
$(cat keys/ta.key)
</tls-auth>
key-direction 1
EOF

echo "Client configuration generated: /tmp/openvpn-clients/$CLIENT_NAME/$CLIENT_NAME.ovpn"
echo "You can copy this file to your client device and use it to connect to the VPN."
