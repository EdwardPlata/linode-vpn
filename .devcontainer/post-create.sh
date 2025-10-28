#!/bin/bash
# Post-create script for Codespaces development environment

set -e

echo "🚀 Setting up Linode VPN development environment..."

# Install additional dependencies
echo "📦 Installing additional dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    sshpass \
    openssh-client \
    curl \
    wget \
    jq \
    make

# Configure Git safe directory
echo "🔧 Configuring Git..."
git config --global --add safe.directory /workspaces/linode-vpn

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
cd terraform
terraform init || echo "⚠️  Terraform init will run when you're ready to deploy"
cd ..

# Create .gitignore for local files if not exists
if [ ! -f ".gitignore" ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Environment files
.env
.env.local
*.ovpn

# IDE files
.vscode/*
!.vscode/extensions.json
.idea/

# SSH keys
*.pem
*.key
id_rsa*

# OS files
.DS_Store
Thumbs.db
EOF
fi

# Check if .env.local exists
if [ -f ".env.local" ]; then
    echo "✅ Found .env.local - environment variables available"
    echo "   Run: source .env.local"
else
    echo "ℹ️  No .env.local found. Run ./setup-env.sh to configure credentials"
fi

# Display helpful information
echo ""
echo "✅ Development environment ready!"
echo ""
echo "📚 Quick Start:"
echo "   1. Configure credentials: ./setup-env.sh"
echo "   2. Load environment: source .env.local"
echo "   3. Deploy VPN: ./deploy.sh"
echo ""
echo "🔍 Useful commands:"
echo "   • Check Terraform: cd terraform && terraform plan"
echo "   • View logs: docker logs openvpn-server"
echo "   • SSH to server: ssh root@<server-ip>"
echo ""
echo "📖 Documentation: README.md"
echo ""
