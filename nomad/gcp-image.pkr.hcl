packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.4"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "gcp_project" {
  type = string
}

variable "gcp_zone" {
  type = string
}

source "googlecompute" "hashistack" {
  image_name   = "hashistack-${local.timestamp}"
  project_id   = var.gcp_project
  source_image = "ubuntu-minimal-2204-jammy-v20231213b"
  ssh_username = "packer"
  zone         = var.gcp_zone
}

build {
  sources = ["sources.googlecompute.hashistack"]

  provisioner "shell" {
    inline = ["sudo mkdir -p /ops/shared", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "../shared"
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=gce"]
    script           = "../shared/scripts/setup.sh"
  }
}