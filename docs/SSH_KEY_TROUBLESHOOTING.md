# SSH Key Troubleshooting Guide

This guide helps resolve SSH public key issues in the Linode VPN GitHub Actions workflow.

## Common Error Messages

### "SSH public key cannot be empty or null"

**Cause**: The `SSH_PUBLIC_KEY` secret is not set or is empty.

**Solution**:
1. Check if the secret exists in GitHub:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Look for `SSH_PUBLIC_KEY` in the list

2. If missing, add the secret:
   - Click "New repository secret"
   - Name: `SSH_PUBLIC_KEY`
   - Value: Your SSH public key (see generation steps below)

### "SSH public key must be in valid SSH public key format"

**Cause**: The SSH key is not in the correct format or is corrupted.

**Solution**:
1. Verify your SSH key format using our validation script:
   ```bash
   ./scripts/validate-ssh-key.sh
   ```

2. A valid SSH public key should look like:
   ```
   ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... user@hostname
   ```
   or
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@hostname
   ```

## SSH Key Generation

### Option 1: Generate new SSH key (Recommended)

```bash
# Generate a new Ed25519 key (most secure)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Display the public key
cat ~/.ssh/id_ed25519.pub
```

### Option 2: Use existing SSH key

```bash
# Check for existing keys
ls -la ~/.ssh/

# Display existing public key (choose one)
cat ~/.ssh/id_rsa.pub        # RSA key
cat ~/.ssh/id_ed25519.pub    # Ed25519 key
cat ~/.ssh/id_ecdsa.pub      # ECDSA key
```

## Setting the GitHub Secret

1. Copy your SSH public key (the entire line starting with `ssh-...`)
2. Go to GitHub repository → Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `SSH_PUBLIC_KEY`
5. Value: Paste the entire public key
6. Click "Add secret"

## Validation Checklist

Before running the workflow, ensure:

- [ ] SSH public key starts with `ssh-rsa`, `ssh-ed25519`, or similar
- [ ] SSH public key is a single line (no line breaks)
- [ ] SSH public key contains no extra spaces at the beginning or end
- [ ] SSH public key has at least 2 parts (key type and key data)
- [ ] `SSH_PUBLIC_KEY` secret is set in GitHub repository settings

## Testing Your SSH Key

You can test your SSH key format locally:

```bash
# Run our validation script
./scripts/validate-ssh-key.sh

# Or manually validate
echo "YOUR_SSH_PUBLIC_KEY_HERE" | grep -E "^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)"
```

## Common Mistakes

1. **Including private key**: Only use the `.pub` file content, never the private key
2. **Line breaks**: SSH keys should be a single line
3. **Extra characters**: Don't add quotes, spaces, or other characters
4. **Wrong file**: Make sure you're using the `.pub` file, not the private key

## Still Having Issues?

1. Delete and recreate the `SSH_PUBLIC_KEY` secret
2. Generate a new SSH key pair
3. Use the validation script to verify the key format
4. Check the GitHub Actions logs for specific error details

## Security Notes

- Never share your private SSH key
- Only use the public key (`.pub` file) for GitHub secrets
- Keep your private key secure on your local machine
- Consider using SSH key passphrases for additional security