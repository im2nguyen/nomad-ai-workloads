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

resource "azurerm_resource_group" "nomad_multicloud" {
  name     = var.name_prefix
  location = var.azure_location
}