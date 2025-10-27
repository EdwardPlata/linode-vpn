#!/bin/bash

# OpenVPN + Pi-hole Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_pihole_header() {
    echo -e "${CYAN}[PI-HOLE]${NC} $1"
}

# Helper function to get environment variable from .env file
get_env_var() {
    local var_name=$1
    if [ -f ".env" ]; then
        grep "^${var_name}=" .env | cut -d '=' -f2-
    fi
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "OpenVPN Commands:"
    echo "  create <client-name>     Create a new client certificate"
    echo "  list                     List all client certificates"
    echo "  status                   Show server status (OpenVPN + Pi-hole)"
    echo "  logs [service]           Show logs (openvpn, pihole, or all)"
    echo "  restart [service]        Restart services (openvpn, pihole, or all)"
    echo
    echo "Pi-hole Commands:"
    echo "  pihole-status            Show Pi-hole status and statistics"
    echo "  pihole-password          Show Pi-hole admin password (use with caution)"
    echo "  pihole-update            Update Pi-hole blocklists"
    echo "  pihole-whitelist <domain> Add domain to whitelist"
    echo "  pihole-blacklist <domain> Add domain to blacklist"
    echo
    echo "Examples:"
    echo "  $0 create john-laptop"
    echo "  $0 list"
    echo "  $0 status"
    echo "  $0 logs pihole"
    echo "  $0 pihole-status"
    echo "  $0 pihole-whitelist example.com"
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
    print_header "Service Status"
    docker-compose ps
    echo
    print_header "Container Resource Usage"
    docker stats --no-stream $(docker-compose ps -q)
    echo
    
    print_pihole_header "Pi-hole Quick Stats"
    docker-compose exec -T pihole pihole -c -e || print_warning "Could not fetch Pi-hole stats"
}

show_logs() {
    local service=$1
    
    if [ -z "$service" ] || [ "$service" = "all" ]; then
        print_header "Showing all logs (Ctrl+C to exit)"
        docker-compose logs -f
    elif [ "$service" = "openvpn" ]; then
        print_header "OpenVPN Logs (Ctrl+C to exit)"
        docker-compose logs -f openvpn
    elif [ "$service" = "pihole" ]; then
        print_pihole_header "Pi-hole Logs (Ctrl+C to exit)"
        docker-compose logs -f pihole
    else
        print_error "Unknown service: $service"
        print_status "Available services: openvpn, pihole, all"
        exit 1
    fi
}

restart_server() {
    local service=$1
    
    if [ -z "$service" ] || [ "$service" = "all" ]; then
        print_status "Restarting all services..."
        docker-compose restart
        print_status "All services restarted"
    elif [ "$service" = "openvpn" ]; then
        print_status "Restarting OpenVPN..."
        docker-compose restart openvpn
        print_status "OpenVPN restarted"
    elif [ "$service" = "pihole" ]; then
        print_status "Restarting Pi-hole..."
        docker-compose restart pihole
        print_status "Pi-hole restarted"
    else
        print_error "Unknown service: $service"
        print_status "Available services: openvpn, pihole, all"
        exit 1
    fi
}

pihole_status() {
    print_pihole_header "Pi-hole Status"
    docker-compose exec pihole pihole status
    echo
    print_pihole_header "Pi-hole Statistics"
    docker-compose exec pihole pihole -c -e
}

pihole_password() {
    print_pihole_header "Pi-hole Admin Password"
    echo "⚠️  This will display sensitive credentials in plain text!" >&2
    echo -n "Continue? [y/N] " >&2
    read -r -t 30 confirm || { print_status "Timeout or EOF - Cancelled"; return; }
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_status "Cancelled"
        return
    fi
    
    echo
    password=$(get_env_var "PIHOLE_PASSWORD")
    server_ip=$(get_env_var "SERVER_IP")
    
    if [ -n "$password" ]; then
        echo "  Password: $password"
        if [ -n "$server_ip" ]; then
            echo "  Web Interface: http://${server_ip}/admin"
        fi
    else
        print_warning "No password set in .env file"
    fi
}

pihole_update() {
    print_pihole_header "Updating Pi-hole blocklists..."
    docker-compose exec pihole pihole -g
    print_status "Pi-hole blocklists updated"
}

pihole_whitelist() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_error "Domain is required"
        echo "Usage: $0 pihole-whitelist <domain>"
        exit 1
    fi
    
    print_pihole_header "Adding $domain to whitelist..."
    docker-compose exec pihole pihole -w "$domain"
    print_status "Domain added to whitelist"
}

pihole_blacklist() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        print_error "Domain is required"
        echo "Usage: $0 pihole-blacklist <domain>"
        exit 1
    fi
    
    print_pihole_header "Adding $domain to blacklist..."
    docker-compose exec pihole pihole -b "$domain"
    print_status "Domain added to blacklist"
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
        show_logs "$2"
        ;;
    "restart")
        restart_server "$2"
        ;;
    "pihole-status")
        pihole_status
        ;;
    "pihole-password")
        pihole_password
        ;;
    "pihole-update")
        pihole_update
        ;;
    "pihole-whitelist")
        pihole_whitelist "$2"
        ;;
    "pihole-blacklist")
        pihole_blacklist "$2"
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
