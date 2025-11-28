#!/bin/bash

# =============================================================================
# Local Deployment Test Script
# Simulates GitHub Actions workflow locally for testing before pushing
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

print_header "🧪 LOCAL GITHUB ACTIONS WORKFLOW TEST"

echo "This script simulates the GitHub Actions workflow locally."
echo "It will validate your configuration and optionally deploy to Linode."
echo ""

# =============================================================================
# Load environment variables
# =============================================================================

# Load .env.local if exists
if [ -f ".env.local" ]; then
    print_step "Loading from .env.local..."
    set -a
    source .env.local
    set +a
fi

# Auto-detect SSH key
if [ -z "$SSH_PUBLIC_KEY" ] && [ -z "$TF_VAR_ssh_public_key" ]; then
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        export SSH_PUBLIC_KEY=$(cat "$HOME/.ssh/id_ed25519.pub")
        print_success "Auto-detected SSH key: id_ed25519.pub"
    elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        export SSH_PUBLIC_KEY=$(cat "$HOME/.ssh/id_rsa.pub")
        print_success "Auto-detected SSH key: id_rsa.pub"
    fi
fi

# Check required variables
print_header "Step 1: Environment Check"

MISSING=()
[ -z "$LINODE_PAT" ] && [ -z "$TF_VAR_linode_api_token" ] && MISSING+=("LINODE_PAT")
[ -z "$SSH_PUBLIC_KEY" ] && [ -z "$TF_VAR_ssh_public_key" ] && MISSING+=("SSH_PUBLIC_KEY")
[ -z "$ROOT_PASSWORD" ] && [ -z "$TF_VAR_root_password" ] && MISSING+=("ROOT_PASSWORD")

if [ ${#MISSING[@]} -gt 0 ]; then
    print_warning "Missing required variables: ${MISSING[*]}"
    echo ""
    echo "Options:"
    echo "  1. Create .env.local file with these variables"
    echo "  2. Export them in your shell"
    echo "  3. Enter them now interactively"
    echo ""
    
    read -p "Enter values now? (y/n): " ENTER
    if [ "$ENTER" = "y" ]; then
        for var in "${MISSING[@]}"; do
            if [ "$var" = "ROOT_PASSWORD" ]; then
                read -s -p "Enter $var: " val
                echo ""
            else
                read -p "Enter $var: " val
            fi
            export "$var"="$val"
        done
    else
        print_error "Cannot proceed without required variables."
        exit 1
    fi
fi

# Map to Terraform variables
export TF_VAR_linode_api_token="${LINODE_PAT:-$TF_VAR_linode_api_token}"
export TF_VAR_ssh_public_key="${SSH_PUBLIC_KEY:-$TF_VAR_ssh_public_key}"
export TF_VAR_root_password="${ROOT_PASSWORD:-$TF_VAR_root_password}"
export TF_VAR_region="${TF_VAR_region:-us-east}"
export TF_VAR_instance_type="${TF_VAR_instance_type:-g6-nanode-1}"
export LINODE_TOKEN="$TF_VAR_linode_api_token"

print_success "All required environment variables are set"

# =============================================================================
# SSH Key Validation
# =============================================================================
print_header "Step 2: SSH Key Validation"

print_step "Checking SSH public key format..."
SSH_KEY="$TF_VAR_ssh_public_key"

if [ -z "$SSH_KEY" ]; then
    print_error "SSH_PUBLIC_KEY is empty"
    exit 1
fi

KEY_TYPES="ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521"
if echo "$SSH_KEY" | grep -E "^($KEY_TYPES)" > /dev/null; then
    KEY_TYPE=$(echo "$SSH_KEY" | cut -d' ' -f1)
    print_success "SSH public key format is valid"
    echo "  Key type: $KEY_TYPE"
else
    print_error "SSH key does not start with a valid key type"
    echo "  Expected: ssh-rsa, ssh-ed25519, or ecdsa-*"
    echo "  Got: $(echo "$SSH_KEY" | cut -c1-30)..."
    exit 1
fi

# =============================================================================
# Terraform Validation
# =============================================================================
print_header "Step 3: Terraform Validation"

cd terraform

print_step "Running terraform init..."
if terraform init -input=false > /dev/null 2>&1; then
    print_success "Terraform initialized"
else
    terraform init -input=false
    print_error "Terraform init failed"
    exit 1
fi

print_step "Running terraform fmt -check..."
if terraform fmt -check > /dev/null 2>&1; then
    print_success "Terraform formatting is correct"
else
    print_warning "Terraform files need formatting (run: terraform fmt)"
fi

print_step "Running terraform validate..."
if terraform validate > /dev/null 2>&1; then
    print_success "Terraform configuration is valid"
else
    terraform validate
    print_error "Terraform validation failed"
    exit 1
fi

print_step "Running terraform plan..."
if terraform plan -out=tfplan > /dev/null 2>&1; then
    print_success "Terraform plan succeeded"
else
    terraform plan -out=tfplan
fi

cd "$PROJECT_ROOT"

# =============================================================================
# Deployment Decision
# =============================================================================
print_header "Step 4: Deployment Decision"

echo "✅ Terraform validation passed! The configuration is ready to deploy."
echo ""
echo "Deployment will create:"
echo "  - Linode Nanode instance (~\$5/month) in ${TF_VAR_region:-us-east}"
echo "  - OpenVPN server with Pi-hole ad-blocking"
echo "  - Firewall rules for VPN (1194/UDP) and web access (80/TCP)"
echo ""

read -p "Do you want to deploy now? (y/n): " DO_DEPLOY

if [ "$DO_DEPLOY" != "y" ]; then
    print_warning "Deployment skipped."
    echo ""
    echo "To deploy manually:"
    echo "  cd terraform && terraform apply tfplan"
    echo ""
    echo "To deploy via GitHub Actions:"
    echo "  git add -A && git commit -m 'Deploy VPN' && git push origin main"
    exit 0
fi

# =============================================================================
# Deploy
# =============================================================================
print_header "Step 5: Deploying VPN Server"

cd terraform

print_step "Applying Terraform configuration..."
terraform apply -auto-approve tfplan

# Capture outputs
VPN_IP=$(terraform output -raw vpn_server_ip 2>/dev/null || echo "")

if [ -z "$VPN_IP" ]; then
    print_error "Failed to get VPN server IP"
    exit 1
fi

print_success "VPN Server deployed at: $VPN_IP"

cd "$PROJECT_ROOT"

# =============================================================================
# Wait for Server Initialization
# =============================================================================
print_header "Step 6: Waiting for Server Initialization"

print_step "Waiting 90 seconds for server to initialize..."
echo -n "Progress: "
for i in {1..18}; do
    echo -n "█"
    sleep 5
done
echo " Done!"

# =============================================================================
# Generate Client Configuration
# =============================================================================
print_header "Step 7: Generating Client Configuration"

print_step "Connecting to server to generate VPN client config..."

# Install sshpass if needed
if ! command -v sshpass &> /dev/null; then
    print_step "Installing sshpass..."
    sudo apt-get update -qq && sudo apt-get install -y sshpass 2>/dev/null || true
fi

# Add to known hosts
mkdir -p ~/.ssh
ssh-keyscan -H "$VPN_IP" >> ~/.ssh/known_hosts 2>/dev/null || true

# Generate client config
print_step "Generating client configurations on server..."

sshpass -p "$TF_VAR_root_password" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 "root@$VPN_IP" << 'REMOTE' || print_warning "Connection issue - server may need more time"
#!/bin/bash
echo "Waiting for OpenVPN container..."
for i in {1..30}; do
    if docker ps 2>/dev/null | grep -q openvpn-server; then
        echo "OpenVPN container is running"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

echo ""
echo "Generating client configurations..."
docker exec openvpn-server /usr/local/bin/generate-client.sh mobile-device 2>/dev/null || echo "mobile-device config pending"
docker exec openvpn-server /usr/local/bin/generate-client.sh laptop 2>/dev/null || echo "laptop config pending"

echo ""
echo "Available client configs:"
ls -la /tmp/openvpn-clients/ 2>/dev/null || echo "Configs will be available shortly"
REMOTE

# =============================================================================
# Display Connection Details
# =============================================================================
print_header "🎉 DEPLOYMENT COMPLETE!"

cat << EOF

═══════════════════════════════════════════════════════════════
                    VPN CONNECTION DETAILS
═══════════════════════════════════════════════════════════════

🌐 SERVER INFORMATION
   IP Address:  $VPN_IP
   Region:      Newark, NJ (us-east)
   Monthly Cost: ~\$5 USD

🔒 OPENVPN CONFIGURATION
   Port:       1194/UDP
   Encryption: AES-256-GCM
   Auth:       SHA256
   DNS:        Pi-hole (10.8.1.2) for ad-blocking

🛡️ PI-HOLE AD-BLOCKING DASHBOARD
   URL: http://$VPN_IP/admin
   
═══════════════════════════════════════════════════════════════
                    HOW TO CONNECT
═══════════════════════════════════════════════════════════════

1️⃣  SSH TO YOUR SERVER
    ssh root@$VPN_IP

2️⃣  GENERATE CLIENT CONFIGS
    docker exec openvpn-server /usr/local/bin/generate-client.sh my-iphone
    docker exec openvpn-server /usr/local/bin/generate-client.sh my-android
    docker exec openvpn-server /usr/local/bin/generate-client.sh my-laptop

3️⃣  VIEW/COPY CONFIG FILE
    cat /tmp/openvpn-clients/<device-name>.ovpn

4️⃣  IMPORT TO OPENVPN APP
    - iOS/Android: Download "OpenVPN Connect" from App Store/Play Store
    - Windows: Download OpenVPN GUI from openvpn.net
    - Mac: Download Tunnelblick (free)
    - Linux: sudo openvpn <device>.ovpn

═══════════════════════════════════════════════════════════════
                    MANAGEMENT COMMANDS
═══════════════════════════════════════════════════════════════

View VPN status:    docker logs openvpn-server
View Pi-hole logs:  docker logs pihole
Restart VPN:        docker restart openvpn-server

🗑️  TO DESTROY (when done testing):
    cd terraform && terraform destroy -auto-approve

═══════════════════════════════════════════════════════════════
EOF

# =============================================================================
# Optional: Send Email Notification
# =============================================================================
if [ -n "$MAIL_TO" ]; then
    print_header "Step 8: Email Notification"
    
    if [ -n "$MAIL_USERNAME" ] && [ -n "$MAIL_PASSWORD" ]; then
        print_step "Sending VPN details to $MAIL_TO..."
        print_warning "Email sending requires GitHub Actions (dawidd6/action-send-mail)"
        echo "The GitHub Actions workflow will send the email automatically."
    else
        print_warning "Email credentials not configured locally."
        echo "Set MAIL_USERNAME and MAIL_PASSWORD for email notifications."
    fi
fi

echo ""
print_success "Local deployment test complete!"
echo ""
echo "Next steps:"
echo "  1. SSH to server and generate client configs"
echo "  2. Import .ovpn file to your OpenVPN app"
echo "  3. Connect and enjoy ad-free, encrypted browsing!"
echo ""
