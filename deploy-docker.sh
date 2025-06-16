#!/bin/bash

# OpenVPN Docker Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Get server IP
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me)
    print_status "Detected server IP: $SERVER_IP"
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file..."
    cp .env.example .env
    sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" .env
    print_status "Please review and update .env file if needed."
fi

# Create client-configs directory
mkdir -p client-configs

# Build and start the OpenVPN server
print_status "Building OpenVPN Docker image..."
docker-compose build

print_status "Starting OpenVPN server..."
docker-compose up -d

# Wait for the server to start
print_status "Waiting for OpenVPN server to initialize..."
sleep 30

# Check if the container is running
if docker-compose ps | grep -q "Up"; then
    print_status "OpenVPN server is running successfully!"
    print_status "Server IP: $SERVER_IP"
    print_status "Port: 1194/UDP"
    echo
    print_status "To generate a client certificate, run:"
    echo "  docker-compose exec openvpn /usr/local/bin/generate-client.sh <client-name>"
    echo
    print_status "To view logs, run:"
    echo "  docker-compose logs -f"
else
    print_error "OpenVPN server failed to start. Check logs with: docker-compose logs"
    exit 1
fi
