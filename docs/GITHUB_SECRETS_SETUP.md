# GitHub Secrets Setup Guide

This guide will help you set up the required GitHub secrets for your Linode VPN deployment.

## Required Secrets

Your GitHub Actions workflow requires the following secrets to be set in your repository:

### 1. LINODE_TOKEN_2025
- **Description**: Your Linode API token
- **How to get it**:
  1. Log in to [Linode Cloud Manager](https://cloud.linode.com/)
  2. Go to your profile (click your avatar) → API Tokens
  3. Create a Personal Access Token with **Read/Write** permissions for:
     - Linodes
     - IPs
     - Events
  4. Copy the token (you won't see it again!)

### 2. SSH_PUBLIC_KEY
- **Description**: Your SSH public key for server access
- **How to get it**:
  ```bash
  # If you already have an SSH key:
  cat ~/.ssh/id_rsa.pub
  
  # If you need to generate a new SSH key:
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  cat ~/.ssh/id_rsa.pub
  ```
- **Format**: Should look like: `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your_email@example.com`

### 3. ROOT_PASSWORD
- **Description**: Root password for the Linode instance
- **Requirements**: 
  - At least 8 characters long
  - Use a strong, unique password
  - Consider using a password manager

### 4. MAIL_USERNAME (Optional - for email notifications)
- **Description**: Gmail address for sending VPN setup emails
- **Example**: `your-email@gmail.com`

### 5. MAIL_PASSWORD (Optional - for email notifications)
- **Description**: Gmail app password (not your regular Gmail password)
- **How to get it**:
  1. Enable 2FA on your Gmail account
  2. Go to Google Account settings → Security → App passwords
  3. Generate an app password for "Mail"

### 6. MAIL_TO (Optional - for email notifications)
- **Description**: Email address to receive VPN setup notifications
- **Example**: `your-email@gmail.com`

## How to Set GitHub Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the exact name and value

## Testing Your Setup

After setting all secrets, you can test by:

1. Making a small commit to the `main` branch
2. Check the **Actions** tab for the workflow run
3. If there are validation errors, the new validation rules will show exactly what's wrong

## Troubleshooting

### "SSH public key cannot be empty" error
- Verify the `SSH_PUBLIC_KEY` secret is set and contains your full public key
- Make sure there are no extra spaces or newlines

### "Linode API token cannot be empty" error
- Verify the `LINODE_TOKEN_2025` secret is set with your valid API token
- Make sure the token has the correct permissions

### "Root password must be at least 8 characters" error
- Verify the `ROOT_PASSWORD` secret is set with a strong password
- Password must be at least 8 characters long

## Security Notes

- Never commit these values to your repository
- Use strong, unique passwords
- Consider rotating your API tokens periodically
- Keep your SSH private key secure and never share it

## Next Steps

Once all secrets are properly configured:
1. Push a commit to trigger the deployment
2. Check the Actions tab to monitor the deployment
3. You'll receive an email with VPN connection details (if email is configured)