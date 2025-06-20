#!/bin/bash
# 🔐 Secure Environment Setup Script
# This script helps you set up environment variables safely without committing secrets

echo "🔐 Setting up secure environment for Linode VPN deployment"
echo "================================================="
echo

# Check if .env.local already exists
if [ -f ".env.local" ]; then
    echo "⚠️  .env.local already exists. Do you want to overwrite it? (y/n)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "❌ Setup cancelled"
        exit 0
    fi
fi

# Get Linode API Token
echo "📝 Please enter your Linode API token:"
echo "   (You can get this from: https://cloud.linode.com/profile/tokens)"
read -s -p "Linode API Token: " linode_token
echo

if [ -z "$linode_token" ]; then
    echo "❌ ERROR: Linode API token is required"
    exit 1
fi

# Get Root Password
echo
echo "📝 Please set a strong root password for your VPN server:"
echo "   (Minimum 12 characters, mix of letters, numbers, symbols)"
read -s -p "Root Password: " root_password
echo
read -s -p "Confirm Root Password: " root_password_confirm
echo

if [ "$root_password" != "$root_password_confirm" ]; then
    echo "❌ ERROR: Passwords do not match"
    exit 1
fi

if [ ${#root_password} -lt 12 ]; then
    echo "❌ ERROR: Password must be at least 12 characters long"
    exit 1
fi

# Get SSH Public Key
echo
echo "📝 SSH Public Key Setup:"
if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo "✅ Found existing SSH public key: $HOME/.ssh/id_rsa.pub"
    ssh_public_key=$(cat "$HOME/.ssh/id_rsa.pub")
    echo "   Using: ${ssh_public_key:0:50}..."
else
    echo "⚠️  No SSH public key found at $HOME/.ssh/id_rsa.pub"
    echo "Do you want to:"
    echo "1) Generate a new SSH key pair"
    echo "2) Enter your SSH public key manually"
    echo "3) Exit and set up SSH keys manually"
    read -p "Choice (1/2/3): " ssh_choice
    
    case $ssh_choice in
        1)
            echo "🔑 Generating new SSH key pair..."
            ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
            ssh_public_key=$(cat "$HOME/.ssh/id_rsa.pub")
            echo "✅ New SSH key generated"
            ;;
        2)
            echo "Please paste your SSH public key:"
            read -r ssh_public_key
            ;;
        3)
            echo "❌ Setup cancelled. Please generate SSH keys first:"
            echo "   ssh-keygen -t rsa -b 4096"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

# Optional settings
echo
echo "📝 Optional settings (press Enter for defaults):"
read -p "Server label [vpn-server]: " server_label
server_label=${server_label:-vpn-server}

read -p "Server region [us-east]: " server_region
server_region=${server_region:-us-east}

# Create .env.local file
echo
echo "💾 Creating .env.local file..."
cat > .env.local << EOF
# 🔐 Local Environment Variables for Linode VPN
# This file is gitignored and should NEVER be committed

# Linode API Configuration
export LINODE_TOKEN="$linode_token"

# Terraform Variables
export TF_VAR_root_password="$root_password"
export TF_VAR_ssh_public_key="$ssh_public_key"
export TF_VAR_server_label="$server_label"
export TF_VAR_server_region="$server_region"

# Load these variables with: source .env.local
EOF

# Create shell profile addition
echo
echo "🔧 Would you like to add these to your shell profile? (y/n)"
echo "   This will automatically load them when you open a new terminal"
read -r add_to_profile

if [ "$add_to_profile" = "y" ] || [ "$add_to_profile" = "Y" ]; then
    # Detect shell
    if [ -n "$ZSH_VERSION" ]; then
        profile_file="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        profile_file="$HOME/.bashrc"
    else
        profile_file="$HOME/.profile"
    fi
    
    echo "# Linode VPN Environment Variables" >> "$profile_file"
    echo "if [ -f \"$(pwd)/.env.local\" ]; then" >> "$profile_file"
    echo "    source \"$(pwd)/.env.local\"" >> "$profile_file"
    echo "fi" >> "$profile_file"
    
    echo "✅ Added to $profile_file"
fi

# Set permissions
chmod 600 .env.local

echo
echo "✅ Setup complete!"
echo "================================================="
echo "📁 Created: .env.local (secure environment file)"
echo "🔐 File permissions: 600 (read/write for owner only)"
echo
echo "🚀 To load the environment variables:"
echo "   source .env.local"
echo
echo "🚀 To deploy your VPN:"
echo "   source .env.local && ./deploy.sh"
echo
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "   • .env.local is gitignored and will not be committed"
echo "   • Never share this file or commit it to version control"
echo "   • Keep your API token and passwords secure"
echo "   • Consider using a password manager"
echo
echo "🔍 Next steps:"
echo "   1. source .env.local"
echo "   2. ./deploy.sh"
echo "   3. Follow the README for client setup"
