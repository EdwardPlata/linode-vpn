# Development Container Configuration

This directory contains the configuration for GitHub Codespaces and VS Code Dev Containers.

## What's Included

- **Ubuntu 22.04** base image
- **Terraform 1.5.7** for infrastructure management
- **Docker-in-Docker** for container operations
- **Git & GitHub CLI** for version control
- **VS Code extensions** for Terraform and Docker

## Purpose

This configuration resolves permission errors that occur when opening the repository in GitHub Codespaces without a devcontainer setup. It ensures:

1. Proper user permissions (runs as `vscode` user)
2. Required tools are pre-installed
3. Terraform is initialized automatically
4. Port forwarding for OpenVPN (1194) and Pi-hole (80)

## Post-Create Setup

The `post-create.sh` script automatically runs after the container is created and:

- Installs additional dependencies (sshpass, openssh-client, jq, make)
- Configures Git safe directory
- Initializes Terraform
- Creates .gitignore if missing
- Displays helpful getting started information

## Usage

### In GitHub Codespaces

1. Click "Code" → "Codespaces" → "Create codespace on main"
2. Wait for the container to build and post-create script to complete
3. Run `./setup-env.sh` to configure your credentials
4. Run `source .env.local && ./deploy.sh` to deploy

### In VS Code with Dev Containers

1. Install the "Dev Containers" extension
2. Open repository in VS Code
3. Press F1 → "Dev Containers: Reopen in Container"
4. Wait for container to build
5. Follow the same steps as Codespaces

## Ports

- **1194/UDP**: OpenVPN server port
- **80/TCP**: Pi-hole web interface

## Environment Variables

The container is configured to mount `.env.local` if it exists. This file should contain:

- `LINODE_TOKEN`: Your Linode API token
- `TF_VAR_root_password`: Server root password
- `TF_VAR_ssh_public_key`: Your SSH public key

**Important**: Never commit `.env.local` to version control!

## Customization

Edit `devcontainer.json` to:
- Add more VS Code extensions
- Install additional tools
- Change the base image
- Add more port forwards
- Modify environment variables

## Troubleshooting

### Permission Denied Errors

If you see permission errors, ensure you're using this devcontainer configuration. The configuration sets `remoteUser` and `containerUser` to `vscode` to avoid permission issues.

### Terraform Init Fails

If Terraform initialization fails during post-create:
```bash
cd terraform
terraform init
```

### Docker Issues

Ensure Docker-in-Docker is working:
```bash
docker ps
```

If Docker isn't running, restart the container or rebuild it.

## More Information

- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [GitHub Codespaces](https://github.com/features/codespaces)
- [Dev Container Features](https://containers.dev/features)
