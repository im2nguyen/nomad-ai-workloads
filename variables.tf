# A prefix to start resource names
locals {
  prefix = "${var.name_prefix}-${random_string.suffix.result}"
}

# Prefix for resource names
variable "name_prefix" {
  description = "The prefix used for all resources in this plan"
  default     = "nomad-multicloud"
}

# Random suffix for resource naming and AWS cloud auto-join
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Used to define datacenter and Nomad region
variable "domain" {
  description = "Domain used to deploy Nomad and to generate TLS certificates."
  default     = "global"
}

# Used to define Nomad domain
variable "datacenter" {
  description = "Datacenter used to deploy Nomad and to generate TLS certificates."
  default     = "dc1"
}

variable "allowlist_ip" {
  description = "IP range to allow access for security groups (set 0.0.0.0/0 for no restriction)"
  default     = "0.0.0.0/0"
}