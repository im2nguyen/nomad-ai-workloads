variable "azure_location" {
  description = "The Azure region to deploy to."
}

variable "azure_image_name" {
  description = "The Azure image to use for the server and client machines. Output from the Packer build process. This is the image NAME not the ID."
}

variable "azure_resource_group_name" {
  description = "The Azure resource group name to use."
}

variable "azure_allowlist_ip" {
  description = "IP to allow access for the security groups (set 0.0.0.0/0 for world)"
  default     = "0.0.0.0/0"
}

variable "azure_client_instance_type" {
  description = "The Azure VM type to use for clients."
  default     = "Standard_B1s"
}

variable "azure_private_client_count" {
  description = "The number of private clients to provision."
  default     = "1"
}

variable "azure_public_client_count" {
  description = "The number of publicly accessible clients to provision."
  default     = "1"
}