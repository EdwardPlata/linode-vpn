terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.16.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "linode" {
  token = var.linode_api_token
  # Token can be provided via:
  # - GitHub Actions: LINODE_TOKEN_2025 secret
  # - Codespaces: LINODE_PAT secret
  # - Local: terraform.tfvars file or TF_VAR_linode_api_token env var
}

# Create a Linode instance for our VPN server
resource "linode_instance" "vpn_server" {
  label           = var.instance_label
  image           = var.instance_image
  region          = var.region
  type            = var.instance_type
  authorized_keys = length(trimspace(var.ssh_public_key)) > 0 ? [trimspace(var.ssh_public_key)] : null
  root_pass       = var.root_password
  tags            = var.tags

  # Install Docker and setup OpenVPN
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y docker.io docker-compose git",
      "systemctl start docker",
      "systemctl enable docker",
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
      "sysctl -p",
      "mkdir -p /opt/openvpn",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = self.ip_address
      timeout  = "5m"
    }
  }

  # Copy Docker OpenVPN files
  provisioner "file" {
    source      = "${path.module}/../docker/"
    destination = "/opt/openvpn/"
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = self.ip_address
      timeout  = "5m"
    }
  }

  # Setup and start OpenVPN container
  provisioner "remote-exec" {
    inline = [
      "cd /opt/openvpn",
      "chmod +x *.sh",
      "echo \"OPENVPN_PUBLIC_IP=${self.ip_address}\" > .env",
      "echo \"OPENVPN_PORT=1194\" >> .env",
      "echo \"OPENVPN_PROTOCOL=udp\" >> .env",
      "./deploy-docker.sh",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = self.ip_address
      timeout  = "15m"
    }
  }

  # Configure firewall for OpenVPN and Pi-hole
  provisioner "remote-exec" {
    inline = [
      "apt-get install -y ufw",
      "ufw allow 22/tcp",
      "ufw allow 1194/udp", # OpenVPN port
      "ufw allow 80/tcp",   # Pi-hole web interface (HTTP - consider HTTPS in production)
      "ufw --force enable",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = self.ip_address
      timeout  = "5m"
    }
  }
}

# Output the VPN server's IP address and connection info
output "vpn_server_ip" {
  value = linode_instance.vpn_server.ip_address
}

output "vpn_server_status" {
  value = linode_instance.vpn_server.status
}

output "connection_info" {
  value = {
    ssh_command       = "ssh root@${linode_instance.vpn_server.ip_address}"
    openvpn_port      = "1194"
    protocol          = "UDP"
    pihole_url        = "http://${linode_instance.vpn_server.ip_address}/admin"
    pihole_note       = "Pi-hole provides DNS-based ad-blocking for all VPN clients"
    client_generation = "Run: docker exec openvpn-server /usr/local/bin/generate-client.sh <client-name>"
    ios_setup         = "Download OpenVPN Connect app from App Store"
  }
}
