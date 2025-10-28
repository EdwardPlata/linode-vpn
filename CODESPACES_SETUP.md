# GitHub Codespaces Setup Guide

This guide will help you set up your Linode VPN deployment using GitHub Codespaces, which provides a fully configured development environment in the cloud.

## Prerequisites

1. A Linode account
2. A Linode API token
3. An SSH key pair
4. Access to GitHub Codespaces

## Step 1: Get Your Linode API Token

1. Log in to [Linode Cloud Manager](https://cloud.linode.com/)
2. Go to your profile (click your avatar) → API Tokens
3. Create a Personal Access Token with **Read/Write** permissions for:
   - Linodes
   - IPs
   - Events
4. Copy the token (you won't see it again!)

## Step 2: Set Up Codespaces Secrets

GitHub Codespaces uses a different secret system than repository secrets. You'll need to set up your secrets at the user level:

1. Go to GitHub Settings → Codespaces
2. Click on "New secret" and add these secrets:

### Required Secrets:

#### LINODE_PAT
- **Value**: Your Linode API token from Step 1
- **Description**: This will be automatically available as an environment variable in your Codespace

#### SSH_PUBLIC_KEY
- **Value**: Your SSH public key
- **How to get it**:
  ```bash
  # If you already have an SSH key:
  cat ~/.ssh/id_rsa.pub
  
  # If you need to generate a new SSH key:
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  cat ~/.ssh/id_rsa.pub
  ```
- **Format**: Should look like: `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your_email@example.com`

#### ROOT_PASSWORD
- **Value**: A strong password for your Linode instance (at least 8 characters)

### Optional Secrets (for email notifications):

#### MAIL_USERNAME
- **Value**: Your Gmail address (e.g., `your-email@gmail.com`)

#### MAIL_PASSWORD
- **Value**: Gmail app password (not your regular Gmail password)
- **How to get it**:
  1. Enable 2FA on your Gmail account
  2. Go to Google Account settings → Security → App passwords
  3. Generate an app password for "Mail"

#### MAIL_TO
- **Value**: Email address to receive VPN setup notifications

## Step 3: Create a Codespace

1. Go to your forked repository on GitHub
2. Click the green "Code" button
3. Click on the "Codespaces" tab
4. Click "Create codespace on main"
5. Wait for the Codespace to initialize (this takes a few minutes)

## Step 4: Deploy Your VPN

Once your Codespace is ready:

1. **Navigate to the terraform directory:**
   ```bash
   cd terraform
   ```

2. **Set up your environment variables:**
   ```bash
   # The LINODE_PAT should already be available from Codespaces secrets
   export TF_VAR_linode_api_token="$LINODE_PAT"
   export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY"
   export TF_VAR_root_password="$ROOT_PASSWORD"
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Deploy your VPN:**
   ```bash
   terraform apply
   ```

6. **Get your VPN details:**
   ```bash
   terraform output
   ```

## Step 5: Generate Client Configuration

After deployment, connect to your server and generate a client configuration:

```bash
# Get the server IP from terraform output
VPN_IP=$(terraform output -raw vpn_server_ip)

# SSH to your server
ssh root@$VPN_IP

# Generate a client configuration
docker exec openvpn-server /usr/local/bin/generate-client.sh my-device

# View the configuration
cat /tmp/openvpn-clients/my-device.ovpn
```

## Advantages of Using Codespaces

- ✅ **No local setup required** - Everything is pre-configured
- ✅ **Consistent environment** - Same setup every time
- ✅ **Access from anywhere** - Works on any device with a browser
- ✅ **No permission issues** - No need to install Docker, Terraform, etc.
- ✅ **Automatic cleanup** - Codespaces auto-delete after inactivity
- ✅ **Free tier available** - GitHub provides free Codespaces hours

## Troubleshooting

### "LINODE_PAT not found" error
- Verify you set up the Codespaces secret correctly
- Make sure you're using the correct secret name: `LINODE_PAT`
- Try restarting the Codespace

### SSH key validation errors
- Make sure your `SSH_PUBLIC_KEY` secret contains the full public key
- Verify the key format starts with `ssh-rsa`, `ssh-ed25519`, etc.

### Terraform permission errors
- Verify your Linode API token has the correct permissions
- Make sure the token hasn't expired

## Cleanup

When you're done:

1. **Destroy the infrastructure:**
   ```bash
   terraform destroy
   ```

2. **Stop the Codespace:**
   - Go to GitHub → Codespaces
   - Stop or delete the Codespace to avoid charges

## Security Notes

- Codespaces secrets are encrypted and only available in your Codespaces
- Never commit credentials to your repository
- Consider rotating your API tokens periodically
- The Codespace will automatically shut down after inactivity

## Next Steps

Once your VPN is deployed:
- [Connect your devices using the OpenVPN configuration](README.md#connecting-your-devices)
- [Access the Pi-hole dashboard for ad-blocking management](README.md#pi-hole-ad-blocking-dashboard)
- [Set up additional client configurations as needed](README.md#generating-additional-client-configurations)