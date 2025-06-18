variable "gcp_project" {
  description = "The GCP project to use."
}

variable "gcp_region" {
  description = "The GCP region to deploy to."
}

variable "gcp_zone" {
  description = "The GCP zone to deploy to."
}

variable "gcp_machine_image" {
  description = "The compute image to use for the server and client machines. Output from the Packer build process."
}

variable "gcp_client_instance_type" {
  description = "The compute engine instance type to use for clients."
  default     = "n4-standard-2"
}

variable "gcp_root_block_device_size" {
  description = "The volume size of the root block device."
  default     = 20
}

variable "gcp_private_client_count" {
  description = "The number of private clients to provision."
  default     = "1"
}

variable "gcp_public_client_count" {
  description = "The number of publicly accessible clients to provision."
  default     = "1"
}