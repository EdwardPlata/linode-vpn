variable "linode_api_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.linode_api_token)) > 0
    error_message = "Linode API token cannot be empty or null. Please ensure LINODE_PAT secret is set in GitHub repository settings."
  }
}

variable "instance_label" {
  description = "Label for the Linode instance"
  type        = string
  default     = "vpn-server"
}

variable "instance_image" {
  description = "Image to use for the Linode instance"
  type        = string
  default     = "linode/ubuntu22.04"
}

variable "region" {
  description = "Region for the Linode instance"
  type        = string
  default     = "us-east" # Change to your preferred region
}

variable "instance_type" {
  description = "Type/size of the Linode instance"
  type        = string
  default     = "g6-nanode-1" # 1GB RAM, 1 CPU
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the Linode instance"
  type        = string

  validation {
    condition     = length(trimspace(var.ssh_public_key)) > 0
    error_message = "SSH public key cannot be empty or null. Please ensure SSH_PUBLIC_KEY secret is set in GitHub repository settings."
  }

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)\\s+[A-Za-z0-9+/]+[=]{0,3}(\\s+.*)?$", var.ssh_public_key))
    error_message = "SSH public key must be in valid SSH public key format (e.g., 'ssh-rsa AAAAB3Nz...')."
  }
}

variable "root_password" {
  description = "Root password for the Linode instance"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.root_password) >= 8
    error_message = "Root password must be at least 8 characters long."
  }

  validation {
    condition     = length(trimspace(var.root_password)) > 0
    error_message = "Root password cannot be empty or null. Please ensure ROOT_PASSWORD secret is set in GitHub repository settings."
  }
}

variable "tags" {
  description = "Tags to apply to the Linode instance"
  type        = list(string)
  default     = ["personal-vpn"]
}
