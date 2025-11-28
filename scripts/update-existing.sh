#!/bin/bash

# =============================================================================
# Update Existing VPN Instance Script
# Updates Docker configuration on an already running VPN server
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() { echo -e "${CYAN}▶ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

print_header "🔄 UPDATE EXISTING VPN INSTANCE"

# =============================================================================
# Load environment and check for server
# =============================================================================

# Load .env.local if exists
[ -f ".env.local" ] && source .env.local

# Check for required variables
if [ -z "$ROOT_PASSWORD" ] && [ -z "$TF_VAR_root_password" ]; then
    print_error "ROOT_PASSWORD not set. Export it or add to .env.local"
    exit 1
fi
ROOT_PASSWORD="${ROOT_PASSWORD:-$TF_VAR_root_password}"

# Try to get VPN IP from terraform state or user input
print_step "Looking for existing VPN server..."

VPN_IP=""

# Check terraform state first
if [ -f "terraform/terraform.tfstate" ]; then
    VPN_IP=$(cd terraform && terraform output -raw vpn_server_ip 2>/dev/null || echo "")
fi

# If not found, check via Linode CLI
if [ -z "$VPN_IP" ] && command -v linode-cli &> /dev/null; then
    if [ -n "$LINODE_PAT" ] || [ -n "$LINODE_CLI_TOKEN" ]; then
        export LINODE_CLI_TOKEN="${LINODE_PAT:-$LINODE_CLI_TOKEN}"
        VPN_IP=$(linode-cli linodes list --label personal-vpn-server --json 2>/dev/null | jq -r '.[0].ipv4[0]' 2>/dev/null || echo "")
    fi
fi

# If still not found, ask user
if [ -z "$VPN_IP" ] || [ "$VPN_IP" = "null" ]; then
    print_warning "Could not auto-detect VPN server IP"
    read -p "Enter VPN server IP address: " VPN_IP
fi

if [ -z "$VPN_IP" ]; then
    print_error "No VPN server IP provided. Exiting."
    exit 1
fi

print_success "Found VPN server at: $VPN_IP"

# =============================================================================
# Verify server is reachable
# =============================================================================
print_header "Step 1: Verify Server Connection"

print_step "Testing SSH connection..."

# Install sshpass if needed
if ! command -v sshpass &> /dev/null; then
    print_step "Installing sshpass..."
    sudo apt-get update -qq && sudo apt-get install -y sshpass 2>/dev/null
fi

# Add to known hosts
mkdir -p ~/.ssh
ssh-keyscan -H "$VPN_IP" >> ~/.ssh/known_hosts 2>/dev/null || true

# Test connection
if sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@$VPN_IP" "echo 'Connected!'" 2>/dev/null; then
    print_success "SSH connection successful"
else
    print_error "Cannot connect to server. Check IP and password."
    exit 1
fi

# =============================================================================
# Upload updated Docker files
# =============================================================================
print_header "Step 2: Upload Updated Docker Files"

print_step "Creating archive of Docker files..."
tar -czf /tmp/docker-update.tar.gz -C docker .

print_step "Uploading to server..."
sshpass -p "$ROOT_PASSWORD" scp -o StrictHostKeyChecking=no \
    /tmp/docker-update.tar.gz "root@$VPN_IP:/tmp/"

print_success "Files uploaded"

# =============================================================================
# Update and restart containers
# =============================================================================
print_header "Step 3: Update Containers"

print_step "Extracting files and restarting containers..."

sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no "root@$VPN_IP" << 'REMOTE'
set -e

echo "📦 Extracting updated files..."
cd /opt/openvpn

# Backup existing configs (preserve client certs)
echo "Backing up PKI data..."
docker cp openvpn-server:/etc/openvpn/pki /tmp/pki-backup 2>/dev/null || echo "No PKI to backup"

# Extract new files
tar -xzf /tmp/docker-update.tar.gz --overwrite
chmod +x *.sh

echo "🔄 Stopping containers..."
docker-compose down || true

echo "🏗️ Rebuilding containers..."
docker-compose build --no-cache

echo "🚀 Starting containers..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 20

# Restore PKI if it was backed up
if [ -d "/tmp/pki-backup" ]; then
    echo "Restoring PKI data..."
    docker cp /tmp/pki-backup openvpn-server:/etc/openvpn/pki 2>/dev/null || echo "PKI restore skipped"
fi

echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Update complete!"
REMOTE

# =============================================================================
# Verify services
# =============================================================================
print_header "Step 4: Verify Services"

print_step "Checking service status..."

sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no "root@$VPN_IP" << 'REMOTE'
echo "=== OpenVPN Server ==="
if docker ps | grep -q openvpn-server; then
    echo "✅ OpenVPN is running"
    docker logs openvpn-server --tail 5 2>/dev/null
else
    echo "❌ OpenVPN not running"
fi

echo ""
echo "=== Pi-hole ==="
if docker ps | grep -q pihole; then
    echo "✅ Pi-hole is running"
else
    echo "❌ Pi-hole not running"
fi

echo ""
echo "=== Client Configurations ==="
ls -la /tmp/openvpn-clients/ 2>/dev/null || echo "No client configs yet"
REMOTE

# =============================================================================
# Summary
# =============================================================================
print_header "🎉 UPDATE COMPLETE!"

cat << EOF

═══════════════════════════════════════════════════════════════
                    UPDATE SUMMARY
═══════════════════════════════════════════════════════════════

✅ Server: $VPN_IP
✅ Docker files updated
✅ Containers rebuilt and restarted

ℹ️  YOUR EXISTING CLIENT CONFIGURATIONS STILL WORK!
   (PKI certificates were preserved)

🔧 To generate new client configs:
   ssh root@$VPN_IP
   docker exec openvpn-server /usr/local/bin/generate-client.sh <device-name>

🛡️ Pi-hole Dashboard: http://$VPN_IP/admin

═══════════════════════════════════════════════════════════════
EOF

print_success "Done!"
