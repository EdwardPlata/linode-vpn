# GitHub Actions Deployment Setup Guide

This guide will walk you through setting up automated VPN deployment using GitHub Actions.

## Prerequisites

- A Linode account with API token
- A GitHub account
- An SSH key pair
- A Gmail account (for email notifications)

## Step 1: Generate Linode API Token

1. Log in to your Linode account at https://cloud.linode.com
2. Click on your profile (top right) → **API Tokens**
3. Click **Create a Personal Access Token**
4. Give it a label like "VPN Deployment 2025"
5. Set expiration as needed
6. Under **Access**, enable:
   - **Linodes**: Read/Write
   - **IPs**: Read/Write
7. Click **Create Token**
8. **Copy the token immediately** - you won't be able to see it again!

## Step 2: Generate SSH Key (if you don't have one)

On your local machine:

```bash
# Generate a new SSH key
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# View your public key
cat ~/.ssh/id_rsa.pub
```

Copy the entire public key (starts with `ssh-rsa`).

## Step 3: Set Up Gmail App Password

You need an App Password (not your regular Gmail password) to send emails:

1. Go to your Google Account: https://myaccount.google.com
2. Select **Security** from the left menu
3. Under "Signing in to Google", enable **2-Step Verification** (if not already enabled)
4. Once 2-Step Verification is enabled, go back to Security
5. Under "Signing in to Google", click **App passwords**
6. Select:
   - **App**: Mail
   - **Device**: Other (Custom name) - enter "VPN Deployment"
7. Click **Generate**
8. **Copy the 16-character password** (no spaces)

**Important:** This is NOT your regular Gmail password - it's a special app-specific password.

## Step 4: Configure GitHub Repository Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each of the following secrets:

### Required Secrets

| Secret Name | Description | Example/Instructions |
|-------------|-------------|---------------------|
| `LINODE_TOKEN_2025` | Your Linode API token from Step 1 | `abc123def456...` |
| `SSH_PUBLIC_KEY` | Your SSH public key from Step 2 | `ssh-rsa AAAAB3NzaC1...` |
| `ROOT_PASSWORD` | A strong password for your VPN server | Generate a strong password (20+ chars) |
| `MAIL_USERNAME` | Your Gmail address | `youremail@gmail.com` |
| `MAIL_PASSWORD` | Gmail app password from Step 3 | `abcdefghijklmnop` (16 chars, no spaces) |
| `MAIL_TO` | Email where you want to receive VPN details | `youremail@gmail.com` or another address |

### How to Add Each Secret

For each secret:
1. Click **New repository secret**
2. Enter the **Name** (exactly as shown above)
3. Enter the **Value**
4. Click **Add secret**

## Step 5: Deploy Your VPN

### Option A: Manual Trigger

1. Go to **Actions** tab in your repository
2. Click on **Terraform Deploy** workflow
3. Click **Run workflow** button
4. Select `main` branch
5. Click **Run workflow**

### Option B: Push to Main Branch

Simply push any commit to the `main` branch, and the workflow will automatically trigger.

```bash
# Make a small change or create an empty commit
git commit --allow-empty -m "Trigger VPN deployment"
git push origin main
```

## Step 6: Monitor Deployment

1. Go to **Actions** tab in your repository
2. Click on the running workflow
3. Watch the progress - it takes about 10-15 minutes
4. Once complete, check your email for VPN connection details!

## What Happens During Deployment

1. **Terraform Init**: Initializes Terraform with Linode provider
2. **Terraform Apply**: Creates a Linode server in Newark, NJ
3. **Server Setup**: Installs Docker, OpenVPN, and Pi-hole
4. **Configuration**: Configures VPN and ad-blocking
5. **Email Notification**: Sends comprehensive setup instructions to your email

## Deployment Specifications

- **Region**: Newark, NJ (us-east)
- **Instance**: Nanode 1GB (g6-nanode-1)
- **Cost**: ~$5/month
- **Operating System**: Ubuntu 22.04 LTS
- **VPN Software**: OpenVPN with Pi-hole
- **VPN Port**: 1194/UDP

## What You'll Receive via Email

After successful deployment, you'll receive an email with:

- ✅ Server IP address
- ✅ Connection details (port, protocol)
- ✅ iOS/iPadOS setup instructions
- ✅ Android setup instructions
- ✅ SSH access commands
- ✅ Pi-hole dashboard URL
- ✅ Client configuration generation commands
- ✅ Troubleshooting tips

## Connecting Your Mobile Device

### iOS/iPadOS

1. Download **OpenVPN Connect** from the App Store
2. SSH to your server (details in email)
3. Generate client config:
   ```bash
   ssh root@YOUR_SERVER_IP
   docker exec openvpn-server /usr/local/bin/generate-client.sh my-iphone
   cat /tmp/openvpn-clients/my-iphone.ovpn
   ```
4. Email the `.ovpn` file to yourself or use AirDrop
5. Open the file on your device
6. Import to OpenVPN Connect
7. Connect!

### Android

1. Download **OpenVPN Connect** from Google Play Store
2. Follow the same steps as iOS to get your `.ovpn` file
3. Import to OpenVPN Connect
4. Connect!

## Troubleshooting

### Workflow Fails

**Check Secrets**: Ensure all 6 secrets are configured correctly
- Go to Settings → Secrets and variables → Actions
- Verify each secret name matches exactly (case-sensitive)

**Linode Token**: Verify your token has the correct permissions:
- Linodes: Read/Write
- IPs: Read/Write

### Email Not Received

**Gmail App Password**: Make sure you're using an app password, not your regular Gmail password
- Must be 16 characters, no spaces
- Generated from https://myaccount.google.com/apppasswords

**Check Email**: The email might be in spam/junk folder

### Can't Connect to VPN

**Wait for Initialization**: The server needs 10-15 minutes after deployment to fully initialize

**Firewall**: Ensure port 1194/UDP is open (handled automatically by the script)

**Check Server Status**:
```bash
ssh root@YOUR_SERVER_IP
docker ps
docker logs openvpn-server
```

## Security Best Practices

1. **Keep Secrets Secure**: Never share or commit your secrets
2. **Strong Passwords**: Use strong, unique passwords for ROOT_PASSWORD
3. **Rotate Tokens**: Periodically rotate your Linode API token
4. **SSH Keys**: Keep your private SSH key secure
5. **VPN Configs**: Don't share your `.ovpn` files with others

## Cost Management

- **Monthly Cost**: ~$5 for Nanode 1GB
- **Bandwidth**: 1TB included (plenty for personal use)
- **Destroy When Not Needed**: Run `terraform destroy` to remove resources

### To Destroy Resources

```bash
cd terraform
terraform destroy
```

Or manually delete the Linode instance from the Linode dashboard.

## Support

- **Documentation**: See [README.md](README.md) for full documentation
- **Issues**: Report issues on GitHub
- **Linode Support**: https://www.linode.com/support/

## Additional Resources

- [OpenVPN Connect App (iOS)](https://apps.apple.com/app/openvpn-connect/id590379981)
- [OpenVPN Connect App (Android)](https://play.google.com/store/apps/details?id=net.openvpn.openvpn)
- [Linode Documentation](https://www.linode.com/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Pi-hole Documentation](https://docs.pi-hole.net/)

---

**Happy Secure Browsing! 🔒🚀**
