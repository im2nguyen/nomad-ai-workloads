#------------------------------------------------------------------------------#
# Cloud Auto Join
#------------------------------------------------------------------------------#

# Random suffix for Auto-join and resource naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Prefix for resource names
variable "prefix" {
  description = "The prefix used for all resources in this plan"
  default     = "learn-nomad-multicloud"
}

# Random prefix for resource names
locals {
  name = "${var.prefix}-${random_string.suffix.result}"
}

# Random Auto-Join for Nomad servers
# Nomad servers will use Nomad to join the cluster
locals {
  retry_join_nomad = "provider=aws tag_key=NomadJoinTag tag_value=auto-join-${random_string.suffix.result}"
}

#------------------------------------------------------------------------------#
# AWS Related Variables
#------------------------------------------------------------------------------#

variable "region" {
  description = "The AWS region to deploy to."
}

variable "ami" {
  description = "The AMI to use for the server and client machines. Output from the Packer build process."
}

variable "allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.micro"
}

variable "client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.medium"
}

variable "root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 16
}

#------------------------------------------------------------------------------#
# Cluster Related Variables
#------------------------------------------------------------------------------#

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

# Number of Nomad server instances to start
variable "server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

# Number of externally accessible Nomad client instances to start
variable "public_client_count" {
  description = "The number of clients to provision."
  default     = "1"
}

# Number of Nomad client instances to start
variable "client_count" {
  description = "The number of clients to provision."
  default     = "3"
}