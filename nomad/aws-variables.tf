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

variable "aws_ami" {
  description = "The AMI to use for the server and client machines. Output from the Packer build process."
}

variable "aws_server_instance_type" {
  description = "The AWS instance type to use for servers."
  default     = "t2.micro"
}

variable "aws_client_instance_type" {
  description = "The AWS instance type to use for clients."
  default     = "t2.medium"
}

variable "aws_root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 16
}

variable "aws_server_count" {
  description = "The number of servers to provision."
  default     = "3"
}

variable "aws_public_client_count" {
  description = "The number of publicly accessible clients to provision."
  default     = "1"
}

variable "aws_client_count" {
  description = "The number of private clients to provision."
  default     = "1"
}