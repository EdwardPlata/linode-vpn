# Documentation Index

This folder contains all setup guides and action documentation for the Linode VPN project.

## 📋 Setup Guides

### **🔐 [OpenVPN-Setup.md](OpenVPN-Setup.md)**
**Comprehensive client setup guide** - Start here after deployment!
- Connect OpenVPN on iOS, Android, Windows, macOS, Linux
- Generate client configurations
- Troubleshooting and security best practices
- Server: `50.116.51.113` | Pi-hole: http://50.116.51.113/admin

### **🔑 [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)**
**Required for CI/CD deployment** - Set up GitHub repository secrets
- Step-by-step secret configuration
- SSH key generation
- Linode API token setup
- Email notification configuration

### **☁️ [CODESPACES_SETUP.md](CODESPACES_SETUP.md)**
**Deploy from browser** - No local setup required
- GitHub Codespaces environment guide
- Environment variable configuration
- Manual deployment steps

### **🤖 [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)**
**Automated CI/CD deployment** - Full automation guide
- GitHub Actions workflow explanation
- Automated email notifications
- Deployment monitoring

## 🛠 Automation Scripts

### **📜 [setup-codespaces.sh](setup-codespaces.sh)**
**Codespaces environment automation**
- Automatically configure environment variables
- Set up Terraform variables
- Quick deployment script

## 📁 Navigation

```
linode-vpn/
├── docs/                    # 📖 Setup and action guides (YOU ARE HERE)
│   ├── OpenVPN-Setup.md     # 🎯 START HERE - Connect your devices
│   ├── GITHUB_SECRETS_SETUP.md
│   ├── CODESPACES_SETUP.md
│   ├── GITHUB_ACTIONS_SETUP.md
│   └── setup-codespaces.sh
├── transcripts/             # 📝 Change documentation and session notes
├── terraform/               # 🏗️ Infrastructure as Code
└── README.md               # 📋 Main project overview
```

## 🚀 Quick Start Workflow

1. **Deploy the server**: Follow [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) or [CODESPACES_SETUP.md](CODESPACES_SETUP.md)
2. **Connect your devices**: Follow [OpenVPN-Setup.md](OpenVPN-Setup.md)
3. **Automate future deployments**: Use [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

## 🆘 Need Help?

- **VPN Connection Issues**: See [OpenVPN-Setup.md#troubleshooting](OpenVPN-Setup.md#-troubleshooting)
- **Deployment Problems**: Check [transcripts/](../transcripts/) for recent problem resolutions
- **CI/CD Failures**: Review [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) for missing secrets

---
📅 **Last Updated**: October 28, 2025  
🏷️ **Version**: v2.0 - Post SSH validation fix