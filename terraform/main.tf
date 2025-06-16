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

  # Install Docker and setup OpenVPN with MFA
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y docker.io docker-compose git libpam-google-authenticator qrencode",
      "systemctl start docker",
      "systemctl enable docker",
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf",
      "sysctl -p",
      "mkdir -p /opt/openvpn",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }

  # Copy Docker OpenVPN files
  provisioner "file" {
    source      = "../docker/"
    destination = "/opt/openvpn/"
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "5m"
    }
  }

  # Setup and start OpenVPN container with MFA
  provisioner "remote-exec" {
    inline = [
      "cd /opt/openvpn",
      "chmod +x *.sh",
      "echo \"OPENVPN_PUBLIC_IP=${self.ip_address}\" > .env",
      "echo \"OPENVPN_PORT=1194\" >> .env",
      "echo \"OPENVPN_PROTOCOL=udp\" >> .env",
      "./setup-mfa.sh",
      "./deploy-docker.sh",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      password    = var.root_password
      host        = self.ip_address
      timeout     = "15m"
    }
  }

  # Configure firewall for OpenVPN
  provisioner "remote-exec" {
    inline = [
      "apt-get install -y ufw",
      "ufw allow 22/tcp",
      "ufw allow 1194/udp", # OpenVPN port
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

# Output the VPN server's IP address and connection info
output "vpn_server_ip" {
  value = linode_instance.vpn_server.ip_address
}

output "vpn_server_status" {
  value = linode_instance.vpn_server.status
}

output "connection_info" {
  value = {
    ssh_command = "ssh root@${linode_instance.vpn_server.ip_address}"
    vpn_user_ssh = "ssh vpnuser@${linode_instance.vpn_server.ip_address}"
    openvpn_port = "1194"
    protocol = "UDP"
    mfa_setup = "QR code and emergency codes available at /home/vpnuser/.google_authenticator"
    mfa_note = "SSH requires both SSH key AND Google Authenticator token"
  }
}
