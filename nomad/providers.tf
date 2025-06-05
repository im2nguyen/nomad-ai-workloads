terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.1"
    }
    nomad = {
      source = "hashicorp/nomad"
      version = "2.3.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.37.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "nomad" {
  address     = "https://${aws_instance.server[0].public_ip}:4646"
  region      = var.domain
  secret_id   = random_uuid.nomad_mgmt_token.result
  ca_pem      = tls_self_signed_cert.datacenter_ca.cert_pem
  skip_verify = true
  ignore_env_vars = {
    "NOMAD_ADDR" : true,
    "NOMAD_TOKEN" : true,
    "NOMAD_CACERT" : true,
    "NOMAD_TLS_SERVER_NAME" : true,
  }
}