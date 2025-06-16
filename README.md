# Linode VPN Deployment with Terraform

This project allows you to quickly deploy a WireGuard VPN server on Linode using Terraform, either locally or via GitHub Actions.

## Prerequisites

- A Linode account and API token
- Terraform installed (v1.0.0 or later) for local deployment
- SSH key pair

## Quick Deployment

For a quick deployment, use the provided deployment script:

1. Update your Linode API token in `terraform/terraform.tfvars`
2. Run the deployment script:
   ```
   ./deploy.sh
   ```
3. Follow the prompts to deploy your VPN server

## Local Setup Instructions

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/linode-vpn.git
   cd linode-vpn
   ```

2. Navigate to the terraform directory:
   ```
   cd terraform
   ```

3. Copy the example tfvars file and update it with your information:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit the `terraform.tfvars` file with your Linode API token, SSH public key, and desired configuration.

4. Initialize Terraform:
   ```
   terraform init
   ```

5. Create a plan and apply it:
   ```
   terraform plan
   terraform apply
   ```

## GitHub Actions Deployment

This repository includes a GitHub Actions workflow for automated deployment:

1. Fork this repository to your GitHub account

2. In your GitHub repository settings, add the following secrets:
   - `LINODE_TOKEN`: Your Linode API token
   - `ROOT_PASSWORD`: Strong password for root user
   - `SSH_PUBLIC_KEY`: Your SSH public key

3. Push changes to the main branch to trigger the deployment automatically, or use the "Run workflow" button in the Actions tab

4. After the deployment completes, you will see the IP address of your VPN server in the GitHub Actions logs.

5. The WireGuard client configuration will be available on the server at `/root/wireguard-clients/client.conf`. You can retrieve it using SSH:
   ```
   ssh root@SERVER_IP "cat /root/wireguard-clients/client.conf" > my-wireguard-config.conf
   ```

6. Import this configuration into your WireGuard client on your device to connect to the VPN.

## Security Considerations

- The default configuration opens SSH (port 22) and WireGuard VPN (port 51820) ports only
- Consider changing the default passwords and SSH keys in production environments
- For enhanced security, consider setting up additional firewall rules or fail2ban

## Customization

You can customize the deployment by modifying the following files:
- `variables.tf`: Adjust default values for instance type, region, etc.
- `main.tf`: Modify the Linode instance configuration or add additional resources
- `scripts/setup-wireguard.sh`: Customize the WireGuard VPN configuration

## License

MIT