#!/bin/bash
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Set up Easy-RSA environment
cd /etc/openvpn/easy-rsa

# Check if PKI is already initialized
if [ ! -f keys/ca.crt ]; then
    log "Initializing PKI and generating certificates..."
    
    # Source the vars file
    source ./vars
    
    # Clean all existing keys and certificates
    ./clean-all
    
    # Build the Certificate Authority
    log "Building Certificate Authority..."
    ./build-ca --batch
    
    # Build the server certificate and key
    log "Building server certificate and key..."
    ./build-key-server --batch server
    
    # Build Diffie-Hellman parameters
    log "Generating Diffie-Hellman parameters..."
    ./build-dh
    
    # Generate TLS authentication key
    log "Generating TLS authentication key..."
    openvpn --genkey --secret keys/ta.key
    
    log "Certificate generation completed!"
else
    log "PKI already initialized, using existing certificates."
fi

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.conf
sysctl -p

# Set up iptables rules for NAT
log "Setting up iptables rules..."
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

# Start OpenVPN server
log "Starting OpenVPN server..."
exec openvpn --config /etc/openvpn/server.conf
