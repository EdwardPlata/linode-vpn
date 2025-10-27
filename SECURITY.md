# 🔐 Security Checklist

## ✅ Before Committing Code

### 1. **Environment Variables**
- [ ] No API tokens in code files
- [ ] No passwords in code files
- [ ] No SSH keys in code files
- [ ] All sensitive data in environment variables

### 2. **Required Environment Variables**
```bash
# Required for deployment
export LINODE_TOKEN="your-linode-api-token"
export TF_VAR_root_password="your-secure-password"
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"

# Optional
export TF_VAR_server_label="my-vpn-server"
export TF_VAR_server_region="us-east"
```

### 3. **Files to NEVER Commit**
- [ ] `terraform.tfvars` - Contains API tokens and passwords
- [ ] `*.ovpn` files - Contains private keys
- [ ] SSH private keys (`id_rsa`, `id_ed25519`, etc.)
- [ ] `.env` files with production secrets
- [ ] Docker volumes with sensitive data
- [ ] Log files that might contain secrets

### 4. **Secure Setup Process**

1. **Clone Repository**
   ```bash
   git clone https://github.com/your-username/linode-vpn.git
   cd linode-vpn
   ```

2. **Set Environment Variables** (DO NOT put these in files)
   ```bash
   # Add to your shell profile (~/.bashrc, ~/.zshrc)
   export LINODE_TOKEN="your-api-token-here"
   export TF_VAR_root_password="your-secure-password-here"
   export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
   ```

3. **Deploy Safely**
   ```bash
   ./deploy.sh
   ```

### 5. **What's Safe to Commit**
- [ ] Example configuration files (`*.example`)
- [ ] Scripts without hardcoded credentials
- [ ] Documentation
- [ ] Terraform configuration files (`.tf`)
- [ ] Docker configurations without secrets

### 6. **Emergency: If You Accidentally Commit Secrets**

1. **Immediately rotate all credentials:**
   - Generate new Linode API token
   - Change all passwords
   - Generate new SSH keys

2. **Remove from git history:**
   ```bash
   # Remove sensitive file from all history
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch terraform/terraform.tfvars' \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push (dangerous!)
   git push origin --force --all
   ```

3. **Update .gitignore and recommit**

### 7. **Production Security Best Practices**
- [ ] Use strong, unique passwords (16+ characters)
- [ ] Enable 2FA on Linode account
- [ ] Regularly rotate API tokens
- [ ] Monitor server logs for unusual activity
- [ ] Keep server software updated
- [ ] Use fail2ban for SSH protection
- [ ] Consider changing default SSH port
- [ ] **Secure Pi-hole web interface**: Do not expose HTTP port 80 to public internet
  - Use SSH tunnel for access: `ssh -L 8080:localhost:80 root@SERVER_IP`
  - Or set up reverse proxy with SSL (nginx + Let's Encrypt)
  - Or restrict port 80 to trusted IPs via firewall

### 8. **Safe Environment Variable Storage**

**For Development:**
```bash
# Create a local .env file (gitignored)
echo "LINODE_TOKEN=your-token" > .env.local
echo "TF_VAR_root_password=your-password" >> .env.local
source .env.local
```

**For Production:**
- Use your CI/CD platform's secret management
- Use cloud provider secret stores
- Use HashiCorp Vault or similar

## 🚨 Emergency Contacts
If you suspect a security breach:
1. Immediately change all passwords and API tokens
2. Review Linode account activity
3. Check server logs for unauthorized access
4. Consider rebuilding the server from scratch

Remember: **Security is not optional!** 🔒
