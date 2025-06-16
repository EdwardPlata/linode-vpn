#!/bin/bash

# Client certificate generation script
set -e

CLIENT_NAME="$1"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name>"
    echo "Example: $0 john-laptop"
    exit 1
fi

echo "=== Generating client certificate for: $CLIENT_NAME ==="

# Navigate to Easy-RSA directory
cd /etc/openvpn/easy-rsa

# Check if client certificate already exists
if [ -f "pki/issued/${CLIENT_NAME}.crt" ]; then
    echo "Client certificate for $CLIENT_NAME already exists!"
    echo "If you want to regenerate, first revoke the existing certificate."
    exit 1
fi

# Generate client certificate and key
echo "Generating client certificate and key..."
./easyrsa build-client-full "$CLIENT_NAME" nopass

# Create client configuration directory if it doesn't exist
mkdir -p /etc/openvpn/client-configs

# Generate client configuration file
cat > "/etc/openvpn/client-configs/${CLIENT_NAME}.ovpn" << EOF
client
dev tun
proto ${OPENVPN_PROTOCOL:-udp}
remote ${OPENVPN_PUBLIC_IP:-changeme} ${OPENVPN_PORT:-1194}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
block-outside-dns
verb 3

<ca>
$(cat /etc/openvpn/keys/ca.crt)
</ca>

<cert>
$(cat "pki/issued/${CLIENT_NAME}.crt")
</cert>

<key>
$(cat "pki/private/${CLIENT_NAME}.key")
</key>

<tls-auth>
$(cat /etc/openvpn/keys/ta.key)
</tls-auth>
key-direction 1
EOF

echo "=== Client certificate generated successfully ==="
echo "Client configuration file: /etc/openvpn/client-configs/${CLIENT_NAME}.ovpn"
echo ""
echo "To download the configuration file from the container:"
echo "docker cp CONTAINER_NAME:/etc/openvpn/client-configs/${CLIENT_NAME}.ovpn ./"
echo ""
echo "To view the configuration file:"
echo "docker exec CONTAINER_NAME cat /etc/openvpn/client-configs/${CLIENT_NAME}.ovpn"
