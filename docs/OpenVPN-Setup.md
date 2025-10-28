# OpenVPN Client Setup Guide

This guide will walk you through connecting to your Linode VPN server using OpenVPN Connect on various devices.

## 📋 Server Information

After successful deployment, you'll have these details:

- **Server Address**: `50.116.51.113` (Your actual server IP)
- **Cloud ID**: Not applicable (this is a self-hosted server)
- **Protocol**: UDP
- **Port**: 1194
- **DNS**: Pi-hole (built-in ad-blocking)

## 🔑 Step 1: Generate Your Client Configuration

First, you need to generate a client configuration file (.ovpn) for your device:

### SSH into Your Server:
```bash
ssh root@50.116.51.113
```

### Generate Client Configuration:
```bash
# Replace 'my-device' with a descriptive name for your device
docker exec openvpn-server /usr/local/bin/generate-client.sh my-device

# View the generated configuration
docker exec openvpn-server cat /etc/openvpn/client-configs/my-device.ovpn
```

### Download Configuration File:
```bash
# Copy the configuration file from the container to the server
docker cp openvpn-server:/etc/openvpn/client-configs/my-device.ovpn ./my-device.ovpn

# Download to your local machine using SCP
scp root@50.116.51.113:./my-device.ovpn ./
```

## 📱 Step 2: Install OpenVPN Connect App

### iOS (iPhone/iPad):
1. Open the **App Store**
2. Search for **"OpenVPN Connect"**
3. Install the official **OpenVPN Connect** app (by OpenVPN Inc.)

### Android:
1. Open **Google Play Store**
2. Search for **"OpenVPN Connect"**
3. Install the official **OpenVPN Connect** app (by OpenVPN Inc.)

### Windows:
1. Go to [OpenVPN.net](https://openvpn.net/client/)
2. Download **OpenVPN Connect for Windows**
3. Install the application

### macOS:
1. Go to [OpenVPN.net](https://openvpn.net/client/)
2. Download **OpenVPN Connect for macOS**
3. Install the application

### Linux:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openvpn

# Use the .ovpn file directly
sudo openvpn --config my-device.ovpn
```

## 📂 Step 3: Import Configuration

### Mobile Devices (iOS/Android):

#### Method 1: Email/AirDrop
1. Email the `.ovpn` file to yourself
2. Open the email on your mobile device
3. Tap the `.ovpn` file attachment
4. Choose **"Open in OpenVPN"** or **"Copy to OpenVPN Connect"**

#### Method 2: Manual Import
1. Open **OpenVPN Connect** app
2. Tap the **"+"** or **"Import"** button
3. Choose **"File"** option
4. Browse and select your `.ovpn` file
5. Tap **"Import"**

#### Method 3: Copy-Paste (if file content is shared)
1. Open **OpenVPN Connect** app
2. Tap **"+"** or **"Import"**
3. Choose **"Paste"** option
4. Paste the entire `.ovpn` file content
5. Tap **"Import"**

### Desktop (Windows/macOS):
1. Open **OpenVPN Connect**
2. Click **"+"** or **"Import Profile"**
3. Choose **"File"** and select your `.ovpn` file
4. Click **"Import"**

## 🔌 Step 4: Connect to VPN

### Mobile/Desktop Apps:
1. Open **OpenVPN Connect**
2. Find your imported profile (named after your device)
3. Toggle the **connection switch** or tap **"Connect"**
4. **Allow VPN permissions** when prompted (first time only)
5. Look for the **VPN icon** in your status bar/system tray

### Linux Terminal:
```bash
sudo openvpn --config my-device.ovpn
```

## ✅ Step 5: Verify Connection

### Check Your IP Address:
- Visit [whatismyipaddress.com](https://whatismyipaddress.com)
- Your IP should show: `50.116.51.113` (your VPN server IP)
- Location should show: Newark, NJ

### Test Ad-Blocking:
- Visit a website with ads (any news site)
- Ads should be blocked automatically
- Access Pi-hole dashboard: http://50.116.51.113/admin

### Test DNS Resolution:
```bash
# Should resolve through your VPN
nslookup google.com
```

## 🛠 Troubleshooting

### Connection Issues:

#### Can't Connect:
1. **Check server status**:
   ```bash
   ssh root@50.116.51.113
   docker ps  # Should show openvpn-server running
   ```

2. **Check firewall**:
   ```bash
   sudo ufw status  # Should allow port 1194/udp
   ```

3. **Restart OpenVPN service**:
   ```bash
   docker restart openvpn-server
   ```

#### Slow Connection:
- Try different VPN servers in OpenVPN Connect settings
- Check your local internet connection
- Consider switching to TCP if UDP doesn't work:
  ```bash
  # Generate TCP configuration
  docker exec openvpn-server /usr/local/bin/generate-client.sh my-device-tcp
  ```

#### DNS Issues:
1. **Check Pi-hole status**:
   ```bash
   docker logs pihole
   ```

2. **Manually set DNS** in OpenVPN Connect:
   - Go to profile settings
   - Set DNS servers: `10.8.0.1` (Pi-hole) or `8.8.8.8` (fallback)

### Mobile-Specific Issues:

#### iOS:
- Go to **Settings > General > VPN & Device Management**
- Ensure OpenVPN profile is active
- Try disconnecting/reconnecting

#### Android:
- Check **Settings > Network & Internet > VPN**
- Ensure OpenVPN has necessary permissions
- Try clearing OpenVPN Connect app cache

## 🔄 Managing Multiple Devices

### Generate Separate Configs:
```bash
# Different devices should have unique names
docker exec openvpn-server /usr/local/bin/generate-client.sh laptop
docker exec openvpn-server /usr/local/bin/generate-client.sh phone
docker exec openvpn-server /usr/local/bin/generate-client.sh tablet
```

### List Active Connections:
```bash
# Check who's connected
docker exec openvpn-server cat /var/log/openvpn/status.log
```

### Revoke Client Access:
```bash
# If you need to revoke a device
ssh root@50.116.51.113
docker exec openvpn-server /usr/local/bin/revoke-client.sh device-name
```

## 🔐 Security Best Practices

1. **Unique configs per device** - Don't share `.ovpn` files between devices
2. **Secure storage** - Keep `.ovpn` files secure, don't share publicly
3. **Regular updates** - Keep OpenVPN Connect app updated
4. **Monitor connections** - Regularly check active connections
5. **Revoke old devices** - Remove access for devices you no longer use

## 📊 Monitoring & Management

### Pi-hole Dashboard:
- **URL**: http://50.116.51.113/admin
- **Password**: `RnWE8iz-` (check container logs if different)
- **Features**:
  - View blocked queries
  - Manage blocklists
  - Whitelist/blacklist domains
  - See connected devices

### Server Management:
```bash
# SSH access
ssh root@50.116.51.113

# Check VPN status
docker ps
docker logs openvpn-server

# Check Pi-hole status
docker logs pihole

# View system resources
htop  # or 'top' if htop not installed
df -h  # disk usage
```

## 🆘 Emergency Access

If you lose VPN access but need to manage the server:

1. **Direct SSH**: `ssh root@50.116.51.113`
2. **Linode Console**: Access through Linode Cloud Manager
3. **Regenerate configs**: Create new client configurations
4. **Reset services**: Restart Docker containers if needed

## 📞 Support Information

- **Server IP**: 50.116.51.113
- **SSH Access**: `ssh root@50.116.51.113`
- **Pi-hole Admin**: http://50.116.51.113/admin
- **OpenVPN Port**: 1194/UDP
- **Cost**: ~$5/month (Linode g6-nanode-1)
- **Location**: Newark, NJ (us-east)

For additional help, refer to:
- [OpenVPN Connect Documentation](https://openvpn.net/connect-docs/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Linode Documentation](https://www.linode.com/docs/)