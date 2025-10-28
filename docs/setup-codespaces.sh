#!/bin/bash

# GitHub Codespaces Environment Setup Script
# This script helps set up environment variables for Terraform deployment

echo "🚀 Setting up Linode VPN deployment in Codespaces..."
echo ""

# Check if we're in Codespaces
if [ "$CODESPACES" != "true" ]; then
    echo "⚠️  Warning: This script is designed for GitHub Codespaces"
    echo "   If you're running locally, use terraform.tfvars instead"
    echo ""
fi

# Check for required Codespaces secrets
echo "📋 Checking Codespaces secrets..."

missing_secrets=()

if [ -z "$LINODE_PAT" ]; then
    missing_secrets+=("LINODE_PAT")
fi

if [ -z "$SSH_PUBLIC_KEY" ]; then
    missing_secrets+=("SSH_PUBLIC_KEY")
fi

if [ -z "$ROOT_PASSWORD" ]; then
    missing_secrets+=("ROOT_PASSWORD")
fi

if [ ${#missing_secrets[@]} -gt 0 ]; then
    echo "❌ Missing required Codespaces secrets:"
    for secret in "${missing_secrets[@]}"; do
        echo "   - $secret"
    done
    echo ""
    echo "Please set these secrets in GitHub Settings → Codespaces → Repository secrets"
    echo "See CODESPACES_SETUP.md for detailed instructions"
    exit 1
fi

echo "✅ All required secrets found!"
echo ""

# Set up Terraform environment variables
echo "🔧 Setting up Terraform environment variables..."

export TF_VAR_linode_api_token="$LINODE_PAT"
export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY"
export TF_VAR_root_password="$ROOT_PASSWORD"

# Optional email configuration
if [ -n "$MAIL_USERNAME" ] && [ -n "$MAIL_PASSWORD" ] && [ -n "$MAIL_TO" ]; then
    echo "📧 Email notifications configured"
    export TF_VAR_mail_username="$MAIL_USERNAME"
    export TF_VAR_mail_password="$MAIL_PASSWORD"
    export TF_VAR_mail_to="$MAIL_TO"
else
    echo "📧 Email notifications not configured (optional)"
fi

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "Next steps:"
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform plan"
echo "4. terraform apply"
echo ""
echo "💡 Tip: Run 'source setup-codespaces.sh' to set these variables in your current shell"

# Create a file with the export commands for manual sourcing
cat > /tmp/terraform-env.sh << EOF
# Source this file to set Terraform environment variables
# Usage: source /tmp/terraform-env.sh

export TF_VAR_linode_api_token="$LINODE_PAT"
export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY"
export TF_VAR_root_password="$ROOT_PASSWORD"

EOF

if [ -n "$MAIL_USERNAME" ]; then
cat >> /tmp/terraform-env.sh << EOF
export TF_VAR_mail_username="$MAIL_USERNAME"
export TF_VAR_mail_password="$MAIL_PASSWORD"
export TF_VAR_mail_to="$MAIL_TO"
EOF
fi

echo "📝 Environment variables saved to /tmp/terraform-env.sh"
echo "   Run 'source /tmp/terraform-env.sh' to load them"