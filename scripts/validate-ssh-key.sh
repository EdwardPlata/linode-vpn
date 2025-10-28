#!/bin/bash

# SSH Key Validation Script
# This script helps validate SSH public keys for use with the Linode VPN project

echo "🔑 SSH Public Key Validation Tool"
echo "================================="
echo

# Function to validate SSH key format
validate_ssh_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        echo "❌ ERROR: SSH key is empty"
        return 1
    fi
    
    # Check if key starts with valid key type
    if echo "$key" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)" > /dev/null; then
        echo "✅ SSH key format is valid"
        key_type=$(echo "$key" | cut -d' ' -f1)
        echo "   Key type: $key_type"
        
        # Check if key has the expected number of parts
        key_parts=$(echo "$key" | wc -w)
        if [ "$key_parts" -ge 2 ]; then
            echo "   Key parts: $key_parts (minimum 2 required)"
            return 0
        else
            echo "❌ ERROR: SSH key appears incomplete (only $key_parts parts)"
            return 1
        fi
    else
        echo "❌ ERROR: SSH key does not start with a valid key type"
        echo "   Expected: ssh-rsa, ssh-ed25519, etc."
        echo "   Found: $(echo "$key" | cut -d' ' -f1)"
        return 1
    fi
}

# Check if SSH key is provided as argument
if [ $# -eq 1 ]; then
    echo "Validating provided SSH key..."
    validate_ssh_key "$1"
    exit $?
fi

# Check for default SSH key locations
echo "Checking for SSH keys in default locations..."
echo

DEFAULT_KEYS=(
    "$HOME/.ssh/id_rsa.pub"
    "$HOME/.ssh/id_ed25519.pub"
    "$HOME/.ssh/id_ecdsa.pub"
)

found_key=false

for key_file in "${DEFAULT_KEYS[@]}"; do
    if [ -f "$key_file" ]; then
        echo "📁 Found: $key_file"
        key_content=$(cat "$key_file")
        echo "   Content: ${key_content:0:50}..."
        
        if validate_ssh_key "$key_content"; then
            echo "   ✅ This key is valid for use with GitHub secrets"
            echo
            echo "📋 Copy this key to your GitHub repository secrets:"
            echo "   Secret name: SSH_PUBLIC_KEY"
            echo "   Secret value:"
            echo "   $key_content"
            found_key=true
        else
            echo "   ❌ This key is not valid"
        fi
        echo
    fi
done

if [ "$found_key" = false ]; then
    echo "🔧 No valid SSH keys found. Let's generate one!"
    echo
    read -p "Enter your email address: " email
    
    if [ -n "$email" ]; then
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        
        if [ $? -eq 0 ]; then
            echo "✅ SSH key generated successfully!"
            echo
            key_content=$(cat "$HOME/.ssh/id_ed25519.pub")
            echo "📋 Copy this key to your GitHub repository secrets:"
            echo "   Secret name: SSH_PUBLIC_KEY"
            echo "   Secret value:"
            echo "   $key_content"
        else
            echo "❌ Failed to generate SSH key"
            exit 1
        fi
    else
        echo "❌ Email address is required for SSH key generation"
        exit 1
    fi
fi

echo
echo "🚀 Next steps:"
echo "1. Copy the SSH public key shown above"
echo "2. Go to your GitHub repository → Settings → Secrets and variables → Actions"
echo "3. Click 'New repository secret'"
echo "4. Name: SSH_PUBLIC_KEY"
echo "5. Value: Paste the entire key (starting with ssh-...)"
echo "6. Click 'Add secret'"