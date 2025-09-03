#-------------------------------------------------------------------------------
# Client Configuration
#-------------------------------------------------------------------------------

variable "size" {
  description = "Size of the client instances (small, medium, large)"
  type        = string
  
  validation {
    condition     = contains(["small", "medium", "large"], var.size)
    error_message = "Client size must be one of: small, medium, large."
  }
}

variable "public" {
  description = "Whether the clients should be public (true) or private (false)"
  type        = bool
}

variable "instance_count" {
  description = "Number of client instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0
    error_message = "Count must be greater than 0."
  }
}

#-------------------------------------------------------------------------------
# Instance Types
#-------------------------------------------------------------------------------

variable "instance_type" {
  description = "AWS instance type for the clients"
  type        = string
  default     = "t2.medium"
}

#-------------------------------------------------------------------------------
# Infrastructure References
#-------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where instances will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Map of security group IDs"
  type = object({
    ssh_ingress           = string
    allow_all_internal    = string
    public_client_ingress = string
  })
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name for instances"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for instances"
  type        = string
}

#-------------------------------------------------------------------------------
# Nomad Configuration
#-------------------------------------------------------------------------------

variable "domain" {
  description = "Domain used for Nomad configuration"
  type        = string
}

variable "datacenter" {
  description = "Datacenter name for Nomad"
  type        = string
}

variable "retry_join" {
  description = "Retry join configuration for Nomad"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "suffix" {
  description = "Random suffix for resource naming and auto-join"
  type        = string
}

#-------------------------------------------------------------------------------
# TLS Certificates
#-------------------------------------------------------------------------------

variable "ca_certificate" {
  description = "Base64 encoded CA certificate"
  type        = string
}

variable "ca_private_key" {
  description = "CA private key for signing client certificates"
  type        = string
  sensitive   = true
}

#-------------------------------------------------------------------------------
# Storage Configuration
#-------------------------------------------------------------------------------

variable "root_block_device_size" {
  description = "Size of the root block device in GB"
  type        = number
  default     = 16
}

variable "ebs_block_device_size" {
  description = "Size of the additional EBS block device in GB"
  type        = number
  default     = 50
}

#-------------------------------------------------------------------------------
# User Data Script
#-------------------------------------------------------------------------------

variable "user_data_script_path" {
  description = "Path to the user data script template"
  type        = string
}
