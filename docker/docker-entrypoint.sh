#!/bin/bash

# Docker entrypoint script for OpenVPN container
set -e

echo "=== OpenVPN Docker Container Starting ==="

# Set default values
OPENVPN_PUBLIC_IP=${OPENVPN_PUBLIC_IP:-"192.168.1.100"}
OPENVPN_PORT=${OPENVPN_PORT:-"1194"}
OPENVPN_PROTOCOL=${OPENVPN_PROTOCOL:-"udp"}
OPENVPN_NETWORK=${OPENVPN_NETWORK:-"10.8.0.0"}
OPENVPN_NETMASK=${OPENVPN_NETMASK:-"255.255.255.0"}

echo "Public IP: $OPENVPN_PUBLIC_IP"
echo "Port: $OPENVPN_PORT"
echo "Protocol: $OPENVPN_PROTOCOL"

# Function to initialize PKI
init_pki() {
    echo "=== Initializing PKI ==="
    cd /etc/openvpn/easy-rsa
    
    # Initialize PKI
    if [ ! -d "pki" ]; then
        ./easyrsa init-pki
        echo "PKI initialized"
    else
        echo "PKI already exists"
    fi
}

# Function to build CA
build_ca() {
    echo "=== Building Certificate Authority ==="
    cd /etc/openvpn/easy-rsa
    
    if [ ! -f "pki/ca.crt" ]; then
        echo "Building CA certificate..."
        expect << EOF
spawn ./easyrsa build-ca nopass
expect "Common Name" { send "OpenVPN-CA\r" }
expect eof
EOF
        echo "CA certificate built"
    else
        echo "CA certificate already exists"
    fi
}

# Function to build server certificate
build_server_cert() {
    echo "=== Building Server Certificate ==="
    cd /etc/openvpn/easy-rsa
    
    if [ ! -f "pki/issued/server.crt" ]; then
        echo "Building server certificate..."
        ./easyrsa build-server-full server nopass
        echo "Server certificate built"
    else
        echo "Server certificate already exists"
    fi
}

# Function to generate DH parameters
generate_dh() {
    echo "=== Generating DH Parameters ==="
    cd /etc/openvpn/easy-rsa
    
    if [ ! -f "pki/dh.pem" ]; then
        echo "Generating DH parameters (this may take a while)..."
        ./easyrsa gen-dh
        echo "DH parameters generated"
    else
        echo "DH parameters already exist"
    fi
}

# Function to generate TLS auth key
generate_ta_key() {
    echo "=== Generating TLS Auth Key ==="
    
    if [ ! -f "/etc/openvpn/keys/ta.key" ]; then
        echo "Generating TLS auth key..."
        openvpn --genkey --secret /etc/openvpn/keys/ta.key
        echo "TLS auth key generated"
    else
        echo "TLS auth key already exists"
    fi
}

# Function to copy certificates
copy_certificates() {
    echo "=== Copying Certificates ==="
    
    cd /etc/openvpn/easy-rsa
    
    # Copy server certificates and keys
    cp pki/ca.crt /etc/openvpn/keys/
    cp pki/issued/server.crt /etc/openvpn/keys/
    cp pki/private/server.key /etc/openvpn/keys/
    cp pki/dh.pem /etc/openvpn/keys/
    
    echo "Certificates copied to /etc/openvpn/keys/"
}

# Function to update server configuration
update_server_config() {
    echo "=== Updating Server Configuration ==="
    
    # Update server.conf with environment variables
    sed -i "s/{{OPENVPN_PORT}}/${OPENVPN_PORT}/g" /etc/openvpn/server.conf
    sed -i "s/{{OPENVPN_PROTOCOL}}/${OPENVPN_PROTOCOL}/g" /etc/openvpn/server.conf
    sed -i "s/{{OPENVPN_NETWORK}}/${OPENVPN_NETWORK}/g" /etc/openvpn/server.conf
    sed -i "s/{{OPENVPN_NETMASK}}/${OPENVPN_NETMASK}/g" /etc/openvpn/server.conf
    
    echo "Server configuration updated"
}

# Function to setup iptables
setup_iptables() {
    echo "=== Setting up iptables ==="
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Setup NAT for VPN traffic
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
    iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
    iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT
    
    echo "iptables rules configured"
}

# Main initialization
main() {
    echo "Starting OpenVPN initialization..."
    
    # Install expect if not present
    which expect >/dev/null || apt-get update && apt-get install -y expect
    
    # Initialize PKI and certificates
    init_pki
    build_ca
    build_server_cert
    generate_dh
    generate_ta_key
    copy_certificates
    update_server_config
    setup_iptables
    
    echo "=== OpenVPN Initialization Complete ==="
    echo "Starting OpenVPN server..."
    
    # Start OpenVPN
    exec openvpn --config /etc/openvpn/server.conf
}

# Check if this is the first argument
if [ "$1" = "start" ] || [ "$1" = "" ]; then
    main
else
    # Execute the provided command
    exec "$@"
fi
