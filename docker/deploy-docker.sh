#!/bin/bash

# OpenVPN + Pi-hole Docker Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Disable systemd-resolved to free up port 53 for Pi-hole
print_status "Checking if systemd-resolved is using port 53..."
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    print_warning "systemd-resolved is running and using port 53. Disabling it for Pi-hole..."
    
    # Stop systemd-resolved
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    
    # Update resolv.conf to use external DNS temporarily
    rm -f /etc/resolv.conf
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    
    print_status "systemd-resolved disabled. Using Cloudflare DNS temporarily."
fi

# Also check if anything else is using port 53
if command -v lsof &> /dev/null && lsof -i :53 2>/dev/null | grep -q LISTEN; then
    print_warning "Port 53 is still in use. Attempting to free it..."
    fuser -k 53/tcp 2>/dev/null || true
    fuser -k 53/udp 2>/dev/null || true
    sleep 2
fi

# Get server IP
if [ -z "$OPENVPN_PUBLIC_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me)
    print_status "Detected server IP: $SERVER_IP"
    export OPENVPN_PUBLIC_IP=$SERVER_IP
else
    SERVER_IP=$OPENVPN_PUBLIC_IP
    print_status "Using provided server IP: $SERVER_IP"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file..."
    cp .env.example .env
    
    # Generate a random password for Pi-hole if not set
    RANDOM_PASSWORD=$(openssl rand -base64 12)
    sed -i "s/PIHOLE_PASSWORD=changeme/PIHOLE_PASSWORD=$RANDOM_PASSWORD/" .env
    print_warning "Generated Pi-hole password: $RANDOM_PASSWORD"
    print_warning "Save this password! You'll need it to access Pi-hole web interface."
fi

# Update .env file with current values
print_status "Updating .env file with server configuration..."
sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" .env
sed -i "s/SERVER_IP=.*/SERVER_IP=$SERVER_IP/" .env

# Create client-configs directory
mkdir -p client-configs

print_title "Building and Starting Services"

# Build and start the services
print_status "Building OpenVPN Docker image..."
docker-compose build

print_status "Starting Pi-hole and OpenVPN services..."
docker-compose up -d

# Wait for the services to start
print_status "Waiting for services to initialize..."
sleep 15

print_status "Waiting for Pi-hole to be ready..."
PIHOLE_READY=false
for i in {1..30}; do
    if docker-compose exec -T pihole pihole status &> /dev/null; then
        PIHOLE_READY=true
        break
    fi
    sleep 2
done

if [ "$PIHOLE_READY" = false ]; then
    print_error "Pi-hole failed to become ready after 60 seconds"
    print_warning "Check logs with: docker-compose logs pihole"
    exit 1
fi

print_status "Waiting for OpenVPN to be ready..."
sleep 15

# Check if the containers are running
if docker-compose ps | grep -q "Up"; then
    print_title "Deployment Successful!"
    
    echo -e "${GREEN}✓ OpenVPN Server:${NC}"
    echo "  - Server IP: $SERVER_IP"
    echo "  - Port: 1194/UDP"
    echo "  - DNS: Pi-hole (Ad-blocking enabled)"
    echo
    
    echo -e "${GREEN}✓ Pi-hole Ad-Blocker:${NC}"
    echo "  - Web Interface: http://$SERVER_IP/admin"
    PIHOLE_PASS=$(grep PIHOLE_PASSWORD .env | cut -d '=' -f2)
    echo "  - Password: $PIHOLE_PASS"
    echo "  - DNS Server: 10.8.1.2 (internal)"
    echo
    
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Generate a client certificate:"
    echo "   docker-compose exec openvpn /usr/local/bin/generate-client.sh <client-name>"
    echo
    echo "2. Access Pi-hole admin panel to customize blocklists:"
    echo "   http://$SERVER_IP/admin"
    echo
    echo "3. View logs:"
    echo "   docker-compose logs -f"
    echo
    
    print_warning "Note: Pi-hole port 80 is exposed for admin interface."
    print_warning "Consider using a reverse proxy with SSL in production."
else
    print_error "Services failed to start. Check logs with: docker-compose logs"
    exit 1
fi
