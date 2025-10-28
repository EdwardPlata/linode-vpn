# VPN Deployment Checklist

Use this checklist to ensure your VPN deployment is properly configured.

## ✅ Pre-Deployment Checklist

### 1. GitHub Repository Secrets Configuration

Navigate to: **Settings** → **Secrets and variables** → **Actions**

Verify all 6 required secrets are configured:

- [ ] `LINODE_TOKEN_2025` - Your Linode API token (from https://cloud.linode.com/profile/tokens)
- [ ] `SSH_PUBLIC_KEY` - Your SSH public key (from `~/.ssh/id_rsa.pub`)
- [ ] `ROOT_PASSWORD` - Strong password for server root access (generate 20+ characters)
- [ ] `MAIL_USERNAME` - Gmail address for sending notifications (e.g., `youremail@gmail.com`)
- [ ] `MAIL_PASSWORD` - Gmail App Password (16 chars from https://myaccount.google.com/apppasswords)
- [ ] `MAIL_TO` - Email address to receive VPN details (can be same as MAIL_USERNAME)

**Important Notes:**
- Secret names are case-sensitive and must match exactly
- `MAIL_PASSWORD` must be a Gmail App Password (not your regular Gmail password)
- Generate a strong `ROOT_PASSWORD` using a password manager

### 2. Linode API Token Permissions

Verify your Linode API token has the required permissions:

- [ ] **Linodes**: Read/Write access
- [ ] **IPs**: Read/Write access

### 3. Gmail Setup

Ensure 2-Step Verification is enabled and App Password is generated:

- [ ] 2-Step Verification enabled on Gmail account
- [ ] App Password generated for "Mail" and "VPN Deployment"
- [ ] App Password copied to `MAIL_PASSWORD` secret (no spaces)

### 4. Repository Setup

- [ ] Repository is forked or you have write access
- [ ] You're working on the `main` branch (or configured branch)
- [ ] GitHub Actions are enabled for the repository

## 🚀 Deployment Steps

### Option 1: Manual Workflow Trigger (Recommended for First Deployment)

1. [ ] Go to **Actions** tab
2. [ ] Select **Terraform Deploy** workflow
3. [ ] Click **Run workflow**
4. [ ] Select `main` branch
5. [ ] Click green **Run workflow** button
6. [ ] Monitor the workflow execution (takes ~10-15 minutes)

### Option 2: Push to Main Branch

1. [ ] Make any commit to main branch
2. [ ] Push to GitHub: `git push origin main`
3. [ ] Workflow triggers automatically

## 📧 Post-Deployment

### Expected Email Notification

Within 15-20 minutes of deployment start, you should receive an email with:

- [ ] Server IP address
- [ ] VPN connection details (port, protocol)
- [ ] iOS/iPadOS setup instructions
- [ ] Android setup instructions
- [ ] SSH access command
- [ ] Pi-hole dashboard URL
- [ ] Client configuration generation commands

### If Email Not Received

Check the following:

1. [ ] Verify workflow completed successfully (green checkmark in Actions tab)
2. [ ] Check spam/junk folder
3. [ ] Verify `MAIL_TO` secret is set correctly
4. [ ] Verify `MAIL_PASSWORD` is the App Password (not regular password)
5. [ ] Review workflow logs for error messages

## 📱 Mobile Device Setup

### iOS/iPadOS

1. [ ] Download **OpenVPN Connect** from App Store
2. [ ] SSH to server: `ssh root@YOUR_SERVER_IP`
3. [ ] Generate config: `docker exec openvpn-server /usr/local/bin/generate-client.sh my-iphone`
4. [ ] View config: `cat /tmp/openvpn-clients/my-iphone.ovpn`
5. [ ] Email/AirDrop the `.ovpn` file to your device
6. [ ] Open file on device → "Open in OpenVPN"
7. [ ] Import and connect

### Android

1. [ ] Download **OpenVPN Connect** from Google Play
2. [ ] Follow steps 2-4 from iOS section above
3. [ ] Transfer `.ovpn` file to Android device
4. [ ] Import to OpenVPN Connect app
5. [ ] Connect

## 🔍 Verification Steps

### Verify Server is Running

```bash
ssh root@YOUR_SERVER_IP

# Check containers
docker ps

# Should see containers:
# - openvpn-server
# - pihole

# Check OpenVPN logs
docker logs openvpn-server

# Check Pi-hole
docker logs pihole
```

### Verify VPN Connection

1. [ ] Connect to VPN on mobile device
2. [ ] Check your public IP: https://whatismyipaddress.com/
3. [ ] IP should match your Linode server IP
4. [ ] Visit: http://ads-blocker.com/testing/
5. [ ] Ads should be blocked

### Verify Pi-hole

1. [ ] Open browser: `http://YOUR_SERVER_IP/admin`
2. [ ] Pi-hole dashboard should load
3. [ ] Can view blocked queries and statistics

## 💰 Cost Tracking

- [ ] Current instance: Nanode 1GB (g6-nanode-1) ≈ $5/month
- [ ] Region: Newark, NJ (us-east)
- [ ] Bandwidth: 1TB included
- [ ] Monitor usage in Linode dashboard

## 🛡️ Security Checklist

- [ ] Strong `ROOT_PASSWORD` configured (20+ characters)
- [ ] SSH keys properly secured (private key never shared)
- [ ] Linode API token kept secure (never committed to git)
- [ ] `.ovpn` files not shared with unauthorized users
- [ ] Gmail App Password stored securely
- [ ] Consider enabling fail2ban on server (optional)
- [ ] Review server logs periodically

## 📊 Monitoring

### Workflow Status

- [ ] Check Actions tab for workflow status
- [ ] Green checkmark = successful deployment
- [ ] Red X = deployment failed (check logs)

### Server Health

- [ ] SSH access working
- [ ] Docker containers running
- [ ] VPN clients can connect
- [ ] Pi-hole blocking ads
- [ ] No unusual CPU/memory usage

## 🗑️ Cleanup (When Needed)

To destroy the VPN server and stop charges:

### Using Terraform

```bash
cd terraform
terraform destroy
```

### Manual Cleanup

1. [ ] Log in to Linode dashboard
2. [ ] Select the VPN server instance
3. [ ] Click **Delete**
4. [ ] Confirm deletion

## 🆘 Troubleshooting Resources

- **Setup Guide**: [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)
- **Documentation**: [README.md](README.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **GitHub Issues**: [Report issues](https://github.com/EdwardPlata/linode-vpn/issues)

## ✅ Success Criteria

Your deployment is successful when:

- [x] Workflow completes with green checkmark
- [x] Email received with connection details
- [x] Can SSH to server
- [x] Docker containers running
- [x] Can connect to VPN from mobile device
- [x] IP address changes when connected to VPN
- [x] Ads are being blocked (test on http://ads-blocker.com/testing/)
- [x] Pi-hole dashboard accessible

---

**Need Help?** Check the [Setup Guide](GITHUB_ACTIONS_SETUP.md) or [README](README.md) for detailed instructions.
