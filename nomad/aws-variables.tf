#------------------------------------------------------------------------------#
# AWS cloud auto-join
#------------------------------------------------------------------------------#

locals {
  retry_join_nomad = "provider=aws tag_key=NomadJoinTag tag_value=auto-join-${random_string.suffix.result}"
}

#------------------------------------------------------------------------------#
# AWS variables
#------------------------------------------------------------------------------#

variable "aws_region" {
  description = "The AWS region to deploy to."
}

variable "aws_server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.medium"
}

variable "aws_root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 16
}

variable "aws_server_count" {
  description = "The number of servers to provision."
  default     = "1"
}

variable "aws_small_instance_type" {
  description = "The AWS instance type for clients in the small node pool."
  default     = "t2.medium"
}

variable "aws_medium_instance_type" {
  description = "The AWS instance type for clients in the medium node pool."
  default     = "t2.large"
}

variable "aws_large_instance_type" {
  description = "The AWS instance type for clients in the large node pool."
  default     = "t2.xlarge"
}

variable "aws_small_private_client_count" {
  description = "The number of private clients to provision in the small node pool."
  default     = "1"
}

variable "aws_small_public_client_count" {
  description = "The number of public clients to provision in the small node pool."
  default     = "1"
}

variable "aws_medium_private_client_count" {
  description = "The number of private clients to provision in the medium node pool."
  default     = "1"
}

variable "aws_medium_public_client_count" {
  description = "The number of public clients to provision in the medium node pool."
  default     = "1"
}

variable "aws_large_private_client_count" {
  description = "The number of private clients to provision in the large node pool."
  default     = "1"
}

variable "aws_large_public_client_count" {
  description = "The number of public clients to provision in the large node pool."
  default     = "1"
}