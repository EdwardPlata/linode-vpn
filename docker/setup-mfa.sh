#!/bin/bash

# OpenVPN MFA Setup Script with Google Authenticator
# This script sets up Multi-Factor Authentication for SSH and prepares for OpenVPN

set -e

echo "=== Setting up Multi-Factor Authentication ==="

# Create a VPN user
VPN_USER="vpnuser"
if ! id "$VPN_USER" &>/dev/null; then
    echo "Creating VPN user: $VPN_USER"
    useradd -m -s /bin/bash $VPN_USER
    echo "$VPN_USER:$(openssl rand -base64 32)" | chpasswd
    usermod -aG sudo $VPN_USER
fi

# Setup Google Authenticator for the VPN user
echo "Setting up Google Authenticator for user: $VPN_USER"
sudo -u $VPN_USER bash -c "
    cd /home/$VPN_USER
    google-authenticator -t -d -f -r 3 -R 30 -W -q
    echo 'MFA setup completed for $VPN_USER'
    echo 'QR Code and emergency codes saved to /home/$VPN_USER/.google_authenticator'
"

# Configure PAM for SSH MFA
echo "Configuring PAM for SSH MFA..."
cat >> /etc/pam.d/sshd << EOF
# Google Authenticator MFA
auth required pam_google_authenticator.so
EOF

# Configure SSH for MFA
echo "Configuring SSH for MFA..."
sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#AuthenticationMethods publickey,keyboard-interactive/AuthenticationMethods publickey,keyboard-interactive/' /etc/ssh/sshd_config

# Add AuthenticationMethods if not present
if ! grep -q "AuthenticationMethods" /etc/ssh/sshd_config; then
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config
fi

# Restart SSH service
systemctl restart sshd

echo "=== MFA Setup Complete ==="
echo "User '$VPN_USER' has been created with MFA enabled"
echo "QR code and emergency codes are in /home/$VPN_USER/.google_authenticator"
echo "SSH now requires both SSH key AND MFA token"

# Display the QR code for easy setup
echo "=== Google Authenticator QR Code ==="
sudo -u $VPN_USER qrencode -t UTF8 < /home/$VPN_USER/.google_authenticator
echo ""
echo "Scan this QR code with Google Authenticator app"
echo "Emergency codes are stored in /home/$VPN_USER/.google_authenticator"
