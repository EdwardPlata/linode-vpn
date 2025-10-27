# Quick Start Guide - OpenVPN + Pi-hole

This guide will help you get your VPN server with ad-blocking up and running in minutes.

## Prerequisites

- Linode account with API token
- SSH key pair (`ssh-keygen` if you don't have one)
- Basic command line knowledge

## 🚀 Deploy in 5 Minutes

### Step 1: Configure Terraform

```bash
# Clone the repository
git clone https://github.com/yourusername/linode-vpn.git
cd linode-vpn/terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your credentials (DON'T commit this file!)
nano terraform.tfvars
```

Set these values in `terraform.tfvars`:
```hcl
linode_api_token = "your-linode-api-token-here"
ssh_public_key = "ssh-rsa AAAAB3... your-key-here"
root_password = "your-secure-password-here"
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy!
terraform apply
```

Type `yes` when prompted. Deployment takes 5-10 minutes.

### Step 3: Get Your Server Info

After deployment completes, note:
- **Server IP**: Shown in terraform output
- **Pi-hole Password**: Auto-generated, shown in deployment output

### Step 4: Create VPN Client Config

SSH into your server:
```bash
ssh root@YOUR_SERVER_IP
cd /opt/openvpn

# Generate client config (replace 'my-phone' with your device name)
docker-compose exec openvpn /usr/local/bin/generate-client.sh my-phone
```

Download the config file:
```bash
# On your local machine
scp root@YOUR_SERVER_IP:/opt/openvpn/client-configs/my-phone/my-phone.ovpn ~/Downloads/
```

### Step 5: Connect from Your Device

#### iPhone/iPad:
1. Install [OpenVPN Connect](https://apps.apple.com/app/openvpn-connect/id590379981) from App Store
2. Email the `.ovpn` file to yourself
3. Open the email on your iPhone
4. Tap the `.ovpn` file → Open in OpenVPN Connect
5. Tap the + button to import
6. Toggle the switch to connect

#### Mac:
1. Install [OpenVPN Connect](https://openvpn.net/client-connect-vpn-for-mac-os/)
2. Open the `.ovpn` file with OpenVPN Connect
3. Click Connect

#### Android:
1. Install OpenVPN Connect from Play Store
2. Import the `.ovpn` file
3. Connect

#### Windows/Linux:
1. Install OpenVPN client
2. Import the `.ovpn` file
3. Connect

### Step 6: Verify It's Working

1. **Check your connection**: Connect to VPN
2. **Test ad-blocking**: Visit http://ads-blocker.com/testing/
3. **Check your IP**: Visit https://whatismyip.com (should show your server's IP)

### Step 7: Access Pi-hole Dashboard

```bash
# Open your browser to:
http://YOUR_SERVER_IP/admin

# Login with the password from deployment output
```

**Security Note**: For production, use SSH tunnel instead:
```bash
ssh -L 8080:localhost:80 root@YOUR_SERVER_IP
# Then access at: http://localhost:8080/admin
```

## 📊 Managing Your VPN

### Create More Client Configs

```bash
cd /opt/openvpn
./vpn-manage.sh create laptop
./vpn-manage.sh create tablet
./vpn-manage.sh list
```

### Check Status

```bash
./vpn-manage.sh status
```

### View Logs

```bash
./vpn-manage.sh logs openvpn
./vpn-manage.sh logs pihole
```

### Pi-hole Management

```bash
# View Pi-hole statistics
./vpn-manage.sh pihole-status

# Update blocklists
./vpn-manage.sh pihole-update

# Whitelist a domain
./vpn-manage.sh pihole-whitelist example.com

# Blacklist a domain
./vpn-manage.sh pihole-blacklist ads.example.com

# Get admin password
./vpn-manage.sh pihole-password
```

## 🔧 Troubleshooting

### Can't Connect to VPN
```bash
# Check services are running
cd /opt/openvpn
docker-compose ps

# View logs
docker-compose logs openvpn

# Restart if needed
docker-compose restart openvpn
```

### Ads Still Showing
1. Clear browser cache and cookies
2. Check Pi-hole is running: `docker-compose ps`
3. Update blocklists: `./vpn-manage.sh pihole-update`
4. Verify DNS in Pi-hole dashboard (Query Log)

### DNS Not Working
```bash
# Restart Pi-hole
cd /opt/openvpn
docker-compose restart pihole

# Check Pi-hole logs
docker-compose logs pihole
```

## 💡 Pro Tips

### Add More Blocklists

1. Access Pi-hole dashboard: http://YOUR_SERVER_IP/admin
2. Go to Settings → Blocklists
3. Add popular lists:
   - `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
   - `https://v.firebog.net/hosts/static/w3kbl.txt`
   - `https://v.firebog.net/hosts/AdguardDNS.txt`

### Monitor Your VPN

```bash
# Real-time resource monitoring
cd /opt/openvpn
docker stats

# Check connected clients
cat /var/log/openvpn/openvpn-status.log
```

### Backup Your Configuration

```bash
# Backup certificates and configs
cd /opt/openvpn
tar -czf vpn-backup-$(date +%Y%m%d).tar.gz \
  client-configs/ .env docker-compose.yml

# Download backup to local machine
scp root@YOUR_SERVER_IP:/opt/openvpn/vpn-backup-*.tar.gz ~/
```

## 📱 Connect Multiple Devices

Generate a config for each device:
```bash
cd /opt/openvpn
./vpn-manage.sh create iphone
./vpn-manage.sh create laptop  
./vpn-manage.sh create tablet
./vpn-manage.sh create android
```

Each device gets its own certificate for security.

## 🔒 Security Checklist

- ✅ Strong Pi-hole admin password (auto-generated)
- ✅ VPN uses AES-256 encryption
- ✅ Certificate-based authentication
- ⚠️ Pi-hole HTTP on port 80 (use SSH tunnel for production)
- ✅ Firewall configured (SSH, OpenVPN, Pi-hole only)

## 💰 Cost

- Linode Nanode (1GB): **$5/month**
- Bandwidth: 1TB included (plenty for personal use)
- **Total**: ~$5/month for private VPN with ad-blocking

## 🎉 You're Done!

You now have:
- ✅ Private VPN server
- ✅ Network-wide ad blocking
- ✅ Enhanced privacy and security
- ✅ Access from anywhere

Enjoy your ad-free internet! 🚀
