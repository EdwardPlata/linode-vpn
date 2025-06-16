#!/bin/bash

# OpenVPN Client Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[OPENVPN]${NC} $1"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  create <client-name>     Create a new client certificate"
    echo "  list                     List all client certificates"
    echo "  revoke <client-name>     Revoke a client certificate"
    echo "  status                   Show OpenVPN server status"
    echo "  logs                     Show OpenVPN server logs"
    echo "  restart                  Restart OpenVPN server"
    echo
    echo "Examples:"
    echo "  $0 create john-laptop"
    echo "  $0 list"
    echo "  $0 revoke john-laptop"
    echo "  $0 status"
}

create_client() {
    local client_name=$1
    
    if [ -z "$client_name" ]; then
        print_error "Client name is required"
        show_usage
        exit 1
    fi
    
    print_status "Creating client certificate for: $client_name"
    docker-compose exec openvpn /usr/local/bin/generate-client.sh "$client_name"
    
    if [ -f "client-configs/$client_name/$client_name.ovpn" ]; then
        print_status "Client certificate created successfully!"
        print_status "Configuration file: client-configs/$client_name/$client_name.ovpn"
        print_status "You can now download this file and use it with your OpenVPN client."
    else
        print_error "Failed to create client certificate"
        exit 1
    fi
}

list_clients() {
    print_header "Listing client certificates..."
    
    if [ -d "client-configs" ]; then
        clients=$(ls client-configs/ 2>/dev/null || true)
        if [ -n "$clients" ]; then
            for client in $clients; do
                echo "  - $client"
            done
        else
            print_warning "No client certificates found"
        fi
    else
        print_warning "Client configs directory not found"
    fi
}

show_status() {
    print_header "OpenVPN Server Status"
    docker-compose ps
    echo
    print_header "Container Resource Usage"
    docker stats --no-stream $(docker-compose ps -q)
}

show_logs() {
    print_header "OpenVPN Server Logs"
    docker-compose logs -f
}

restart_server() {
    print_status "Restarting OpenVPN server..."
    docker-compose restart
    print_status "OpenVPN server restarted"
}

# Main script logic
case "$1" in
    "create")
        create_client "$2"
        ;;
    "list")
        list_clients
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_server
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
