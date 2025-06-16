# Linode OpenVPN Deployment with Terraform & Docker

This project deploys an OpenVPN server on Linode using Terraform and Docker, with easy client configuration generation for Apple devices (iOS/macOS) and other platforms.

## Prerequisites

- A Linode account and API token
- Terraform installed (v1.0.0 or later)
- SSH key pair
- OpenVPN Connect app on your Apple device (iOS/macOS)

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
3. You're now protected by your personal VPN!

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
- SSH access: **Port 22** (consider changing in production)
- All VPN traffic is encrypted with **AES-256-CBC**
- TLS authentication provides additional security layer
- Consider setting up fail2ban for SSH protection

## Technical Details

- **OS**: Ubuntu 22.04 LTS
- **VPN Software**: OpenVPN 2.6+
- **Containerization**: Docker
- **Certificate Authority**: Easy-RSA 3.x
- **VPN Network**: 10.8.0.0/24
- **DNS Servers**: Google DNS (8.8.8.8, 8.8.4.4)

## Cost Estimation

- **Linode Nanode 1GB**: ~$5/month
- **Bandwidth**: 1TB included (plenty for personal VPN use)
- **Total**: ~$5/month for unlimited personal VPN access

## License

MIT License - Feel free to modify and distribute!