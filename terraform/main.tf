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
  # Token will be provided via GitHub secret LINODE_TOKEN
}

# Create a Linode instance for our VPN server
resource "linode_instance" "vpn_server" {
  label           = var.instance_label
  image           = var.instance_image
  region          = var.region
  type            = var.instance_type
  authorized_keys = [var.ssh_public_key]
  root_pass       = var.root_password
  tags            = var.tags

  # Install and configure WireGuard VPN
  # A more robust solution would use a separate provisioner or user_data
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y wireguard wireguard-tools",
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
      "sysctl -p",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }

  # Copy our WireGuard configuration script
  provisioner "file" {
    source      = "../scripts/setup-wireguard.sh"
    destination = "/root/setup-wireguard.sh"
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }

  # Run the WireGuard setup script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/setup-wireguard.sh",
      "/root/setup-wireguard.sh",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }

  # Configure firewall
  provisioner "remote-exec" {
    inline = [
      "apt-get install -y ufw",
      "ufw allow 22/tcp",
      "ufw allow 51820/udp", # WireGuard port
      "ufw --force enable",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }
}

# Output the VPN server's IP address
output "vpn_server_ip" {
  value = linode_instance.vpn_server.ip_address
}
