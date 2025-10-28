# Linode OpenVPN Deployment with Pi-hole Ad-Blocking

This project deploys an OpenVPN server with integrated Pi-hole ad-blocking on Linode using Terraform and Docker. Enjoy a private VPN with network-wide ad blocking, tracker blocking, and enhanced privacy for all your devices.

## ✨ Features

- 🔒 **Secure OpenVPN Server** - Industry-standard VPN with AES-256 encryption
- 🚫 **Network-Wide Ad Blocking** - Pi-hole blocks ads, trackers, and malicious domains at the DNS level
- 🍎 **Easy Apple Device Setup** - Simple configuration for iOS and macOS
- 🌐 **All Devices Protected** - Blocks ads on phones, tablets, computers, smart TVs, and more
- 📊 **Web Management Interface** - Pi-hole dashboard to monitor and configure blocking
- 💰 **Cost-Effective** - Run your own VPN + ad-blocker for ~$5/month
- 📧 **Automated Email Notifications** - Receive detailed VPN connection instructions via email after deployment
- 🤖 **GitHub Actions Automation** - Fully automated deployment using Terraform

## 🚀 Quick Start

**New to this project?** Choose your deployment method:
- **[GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md)** - Automated deployment (Recommended)
- **[Quick Start Guide](QUICKSTART.md)** - Local deployment

## 🔒 Security Notice

**NEVER commit credentials to git!** This repository is configured to ignore sensitive files, but always verify before committing:
- API tokens
- SSH private keys
- Passwords
- Client VPN configurations (.ovpn files)

## Prerequisites

- A Linode account and API token
- Terraform installed (v1.0.0 or later)
- SSH key pair
- OpenVPN Connect app on your Apple device (iOS/macOS)

## 🔧 Environment Setup (IMPORTANT)

### For Local Development:
1. **Copy the example file:**
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. **Set your credentials securely:**
   ```bash
   # Option 1: Use environment variables (recommended)
   export TF_VAR_linode_api_token="your-linode-token"
   export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
   export TF_VAR_root_password="your-secure-password"
   
   # Option 2: Edit terraform.tfvars (but NEVER commit it)
   # Edit terraform/terraform.tfvars with your actual values
   ```

3. **VERIFY your credentials are not in git:**
   ```bash
   git status  # terraform.tfvars should NOT appear here
   ```

### For GitHub Actions:
Set these as GitHub repository secrets:
- `LINODE_TOKEN_2025`: Your Linode API token (updated for 2025)
- `SSH_PUBLIC_KEY`: Your SSH public key
- `ROOT_PASSWORD`: Server root password
- `MAIL_USERNAME`: Gmail address for sending VPN details (e.g., youremail@gmail.com)
- `MAIL_PASSWORD`: Gmail app password (not regular password - generate at https://myaccount.google.com/apppasswords)
- `MAIL_TO`: Email address to receive VPN connection details

**📧 Email Configuration Note:**
For Gmail users, you need to generate an App Password (not your regular Gmail password):
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Other (Custom name)"
3. Generate and copy the 16-character password
4. Use this as your `MAIL_PASSWORD` secret

## Deployment Options

### Option 1: GitHub Actions (Recommended)

The easiest way to deploy is using GitHub Actions, which will automatically:
- Deploy your VPN server to Linode (Newark, NJ region)
- Configure OpenVPN with Pi-hole ad-blocking
- Send you an email with all connection details

**Steps:**
1. Fork this repository
2. Configure the GitHub secrets listed above in your repository settings
3. Push to the `main` branch or manually trigger the workflow
4. Wait for the workflow to complete (~10-15 minutes)
5. Check your email for VPN connection instructions!

**Deployment Details:**
- **Region:** Newark, NJ (us-east)
- **Instance Type:** Nanode 1GB (g6-nanode-1) - ~$5/month
- **Automation:** Full Terraform-based infrastructure as code

### Option 2: Local Deployment

## Quick Deployment

1. **Clone and setup:**
   ```bash
   git clone https://github.com/yourusername/linode-vpn.git
   cd linode-vpn/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Configure your settings** in `terraform.tfvars`:
   ```hcl
   linode_token = "your-linode-api-token"
   ssh_public_key = "your-ssh-public-key"
   root_password = "your-secure-password"
   ```

3. **Deploy the infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Your VPN server will be deployed!** Note the server IP from the output.

## 🍎 Connect from Apple Devices (iOS/macOS)

### Step 1: Download OpenVPN Connect
- **iOS**: Download [OpenVPN Connect](https://apps.apple.com/app/openvpn-connect/id590379981) from the App Store
- **macOS**: Download [OpenVPN Connect](https://openvpn.net/client-connect-vpn-for-mac-os/) from the official website

### Step 2: Generate Client Configuration
SSH into your server and create a client profile:
```bash
# SSH into your server (replace with your server IP)
ssh root@YOUR_SERVER_IP

# Generate a client configuration (replace 'my-iphone' with any name)
docker exec openvpn-server /usr/local/bin/generate-client.sh my-iphone

# Download the configuration file
cat /tmp/openvpn-clients/my-iphone.ovpn
```

### Step 3: Import Configuration to Your Apple Device

**For iOS:**
1. Copy the `.ovpn` file content
2. Email it to yourself or use AirDrop
3. Open the email/file on your iPhone/iPad
4. Tap the `.ovpn` file
5. Choose "Open in OpenVPN"
6. Tap the "+" to import
7. Tap "Connect"

**For macOS:**
1. Save the `.ovpn` file to your Mac
2. Double-click the file to open it in OpenVPN Connect
3. Import the profile
4. Click "Connect"

### Step 4: Connect to Your VPN
1. Open the OpenVPN Connect app
2. Toggle the connection switch to connect
3. You're now protected by your personal VPN with ad-blocking!

### Step 5: Verify Ad-Blocking is Working
1. While connected to VPN, visit: http://ads-blocker.com/testing/
2. You should see ads being blocked
3. Check Pi-hole dashboard at http://YOUR_SERVER_IP/admin to see blocked queries

## 🖥️ Connect from Other Devices

### Windows/Linux/Android
1. Install OpenVPN client for your platform
2. Generate a client configuration (Step 2 above)
3. Import the `.ovpn` file
4. Connect

## Server Management

### Check VPN Status
```bash
ssh root@YOUR_SERVER_IP
docker ps                           # Check if container is running
docker logs openvpn-server          # View server logs
```

### Generate Additional Client Configurations
```bash
# Generate config for another device
docker exec openvpn-server /usr/local/bin/generate-client.sh my-laptop
docker exec openvpn-server /usr/local/bin/generate-client.sh my-android

# List all client configurations
ls /tmp/openvpn-clients/
```

### Restart VPN Server
```bash
docker restart openvpn-server
```

## Troubleshooting

### Container Won't Start
```bash
# Check container status
docker ps -a

# View detailed logs
docker logs openvpn-server

# Restart with clean state
docker stop openvpn-server
docker rm openvpn-server
cd /root/docker
docker-compose up -d --build
```

### Can't Connect from Apple Device
1. Ensure you're using the **OpenVPN Connect** app (not other OpenVPN apps)
2. Check that your server IP is correct in the `.ovpn` file
3. Verify the server is running: `docker ps`
4. Check firewall: `iptables -L` and `ufw status`

### Performance Issues
- Try different OpenVPN protocols/ports in the server configuration
- Check server resources: `htop` or `docker stats`

## Security Considerations

- Default OpenVPN port: **1194/UDP**
- Pi-hole web interface: **Port 80 (HTTP)** 
  - ⚠️ **Security Warning**: HTTP is unencrypted. For production use:
    - Use SSH tunnel: `ssh -L 8080:localhost:80 root@SERVER_IP` then access at `http://localhost:8080/admin`
    - Or set up nginx reverse proxy with Let's Encrypt SSL
    - Or restrict access to trusted IPs via firewall rules
- SSH access: **Port 22** (consider changing in production)
- All VPN traffic is encrypted with **AES-256-CBC**
- TLS authentication provides additional security layer
- Pi-hole blocks malicious domains for added security
- Consider setting up fail2ban for SSH protection
- Use strong Pi-hole admin password (auto-generated during deployment)
- Never expose Pi-hole web interface to public internet without SSL

## Technical Details

- **OS**: Ubuntu 22.04 LTS
- **VPN Software**: OpenVPN 2.6+
- **Ad-Blocking**: Pi-hole (DNS-based filtering)
- **Containerization**: Docker & Docker Compose
- **Certificate Authority**: Easy-RSA 3.x
- **VPN Network**: 10.8.0.0/24
- **DNS Server**: Pi-hole (10.8.1.2) with Cloudflare DNS upstream
- **Encryption**: AES-256-CBC with TLS authentication

## Ad-Blocking with Pi-hole

### What is Pi-hole?

Pi-hole is a DNS-based ad-blocker that blocks ads at the network level before they even reach your devices:

- **Blocks Ads Everywhere**: Works on all apps and websites
- **Blocks Trackers**: Prevents tracking across the web
- **Faster Browsing**: Pages load faster without ads
- **Saves Bandwidth**: Reduces data usage
- **Privacy Protection**: Prevents data collection

### How It Works

1. Your device connects to the VPN
2. All DNS queries go through Pi-hole
3. Pi-hole checks domain against blocklists
4. Ads and trackers are blocked, legitimate traffic passes through
5. You browse the web ad-free!

### Managing Pi-hole

Access the Pi-hole web interface:
```
http://YOUR_SERVER_IP/admin
```

Use the password generated during deployment (found in the deployment output).

**Pi-hole Dashboard Features:**
- View real-time query statistics
- Add custom blocklists
- Whitelist/blacklist specific domains
- See top blocked domains
- Monitor query logs

### Default Blocklists

Pi-hole comes pre-configured with popular blocklists that block:
- Advertising domains
- Tracking and analytics
- Malware and phishing sites
- Cryptomining scripts

You can add more blocklists through the web interface under Settings → Blocklists.

## Cost Estimation

- **Linode Nanode 1GB**: ~$5/month
- **Bandwidth**: 1TB included (plenty for personal VPN use)
- **Total**: ~$5/month for unlimited personal VPN access

## License

MIT License - Feel free to modify and distribute!