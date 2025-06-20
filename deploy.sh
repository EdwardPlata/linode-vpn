#!/bin/bash
# Deployment script for Linode VPN

# Check if LINODE_TOKEN environment variable is set
if [ -z "$LINODE_TOKEN" ]; then
  echo "ERROR: LINODE_TOKEN environment variable is not set"
  echo "Please set your Linode API token with: export LINODE_TOKEN=your_token_here"
  exit 1
fi

# Set Terraform variables from environment variables
export TF_VAR_linode_api_token="$LINODE_TOKEN"

# If root password is not explicitly set, prompt for it
if [ -z "$TF_VAR_root_password" ]; then
  echo "⚠️  WARNING: TF_VAR_root_password environment variable is not set"
  echo "Please set a strong root password:"
  read -s -p "Enter root password: " root_password
  echo
  read -s -p "Confirm root password: " root_password_confirm
  echo
  
  if [ "$root_password" != "$root_password_confirm" ]; then
    echo "❌ ERROR: Passwords do not match"
    exit 1
  fi
  
  if [ ${#root_password} -lt 12 ]; then
    echo "❌ ERROR: Password must be at least 12 characters long"
    exit 1
  fi
  
  export TF_VAR_root_password="$root_password"
  echo "✅ Password set successfully"
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform (in case it hasn't been done yet)
echo "Initializing Terraform..."
terraform init

# Create execution plan
echo "Creating execution plan..."
terraform plan

# Ask for confirmation
echo ""
echo "Review the plan above. Do you want to apply these changes? (yes/no)"
read response
if [ "$response" != "yes" ]; then
  echo "Deployment canceled."
  exit 0
fi

# Apply changes
echo "Applying changes..."
terraform apply -auto-approve

# Display information about the newly created instance
echo ""
echo "==============================================" 
echo "🚀 Deployment complete! Your Linode VPN instance has been created."
echo "=============================================="
echo ""
# Get the IP address directly
SERVER_IP=$(terraform output -raw vpn_server_ip)
echo "📝 Your VPN server IP: $SERVER_IP"
echo ""
echo "📊 To retrieve the WireGuard client configuration, run:"
echo "ssh root@$SERVER_IP 'cat /root/wireguard-clients/client.conf' > my-wireguard-config.conf"
echo ""
echo "💻 Then import the configuration file into your WireGuard client"
echo ""
echo "❌ To destroy this infrastructure when no longer needed:"
echo "cd terraform && terraform destroy"
