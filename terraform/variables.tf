variable "linode_api_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
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
  default     = "us-east"  # Change to your preferred region
}

variable "instance_type" {
  description = "Type/size of the Linode instance"
  type        = string
  default     = "g6-nanode-1"  # 1GB RAM, 1 CPU
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the Linode instance"
  type        = string
}

variable "root_password" {
  description = "Root password for the Linode instance"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to the Linode instance"
  type        = list(string)
  default     = ["personal-vpn"]
}
