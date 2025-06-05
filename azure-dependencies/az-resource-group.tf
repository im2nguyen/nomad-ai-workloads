# This config creates the resource group that will contain
# all of the other resources. It needs to be created before
# anything else as the VM image is stored in it.

terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  name = "nomad-multicloud"
  location = "eastus"
}
resource "azurerm_resource_group" "nomad-multicloud" {
  name     = local.name
  location = local.location
}