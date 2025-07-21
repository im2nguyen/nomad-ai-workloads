# NOTE: These must match the values set in /nomad/variables.hcl
locals {
  azure_resource_group_name   = "nomad-multicloud"
  azure_location              = "eastus"
}

resource "azurerm_resource_group" "nomad_multicloud" {
  name                        = local.azure_resource_group_name
  location                    = local.azure_location
}

data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

resource "random_uuid" "nomad_id" {
}

resource "random_uuid" "nomad_token" {
}

resource "random_string" "vm_password" {
  length           = 16
  special          = false
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

# data "azurerm_resource_group" "nomad_multicloud" {
#   name = "${var.name_prefix}"
# }

resource "azurerm_virtual_network" "nomad_multicloud_vn" {
  name                = "${local.prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.nomad_multicloud.name}"
}

# Private clients

resource "azurerm_subnet" "private_clients_subnet" {
  name                 = "${local.prefix}-private-clients-subnet"
  resource_group_name  = "${azurerm_resource_group.nomad_multicloud.name}"
  virtual_network_name = "${azurerm_virtual_network.nomad_multicloud_vn.name}"
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "private_clients_security_group" {
  name                = "${local.prefix}-private-clients-sg"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.nomad_multicloud.name}"
}

resource "azurerm_subnet_network_security_group_association" "private_clients_sg_association" {
  subnet_id                 = azurerm_subnet.private_clients_subnet.id
  network_security_group_id = azurerm_network_security_group.private_clients_security_group.id
}

resource "azurerm_network_security_rule" "private_clients_outbound" {
  name                        = "${local.prefix}-private-clients-outbound"
  resource_group_name         = "${azurerm_resource_group.nomad_multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.private_clients_security_group.name}"

  priority  = 110
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "private_clients_ssh_ingress" {
  name                        = "${local.prefix}-private-clients-ssh-ingress"
  resource_group_name         = "${azurerm_resource_group.nomad_multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.private_clients_security_group.name}"

  priority  = 111
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
}

resource "azurerm_public_ip" "private_client_public_ip" {
  count                        = "${var.azure_private_client_count}"
  name                         = "${local.prefix}-private-client-ip-${count.index}"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.nomad_multicloud.name}"
  allocation_method            = "Static"
  sku                          = "Standard" 
}

resource "azurerm_network_interface" "private_client_ni" {
  count                     = "${var.azure_private_client_count}"
  name                      = "${local.prefix}-private-client-ni-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.nomad_multicloud.name}"

  ip_configuration {
    name                          = "${local.prefix}-private-client-ipc"
    subnet_id                     = "${azurerm_subnet.private_clients_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.private_client_public_ip.*.id, count.index)}"
  }
}

# Public clients

resource "azurerm_subnet" "public_clients_subnet" {
  name                 = "${local.prefix}-public-clients-subnet"
  resource_group_name  = "${azurerm_resource_group.nomad_multicloud.name}"
  virtual_network_name = "${azurerm_virtual_network.nomad_multicloud_vn.name}"
  address_prefixes       = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "public_clients_security_group" {
  name                = "${local.prefix}-public-clients-sg"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.nomad_multicloud.name}"
}

resource "azurerm_subnet_network_security_group_association" "public_clients_sg_association" {
  subnet_id                 = azurerm_subnet.public_clients_subnet.id
  network_security_group_id = azurerm_network_security_group.public_clients_security_group.id
}

resource "azurerm_network_security_rule" "public_clients_outbound" {
  name                        = "${local.prefix}-public-clients-outbound"
  resource_group_name         = "${azurerm_resource_group.nomad_multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.public_clients_security_group.name}"

  priority  = 210
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "public_clients_ssh_ingress" {
  name                        = "${local.prefix}-public-clients-ssh-ingress"
  resource_group_name         = "${azurerm_resource_group.nomad_multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.public_clients_security_group.name}"

  priority  = 211
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "public_clients_external_ingress" {
  name                        = "${local.prefix}-public-clients-external-ingress"
  resource_group_name         = "${azurerm_resource_group.nomad_multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.public_clients_security_group.name}"

  priority  = 212
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_port_ranges    = ["80"]
  destination_address_prefix = "*"
}

resource "azurerm_public_ip" "public_client_public_ip" {
  count                        = "${var.azure_public_client_count}"
  name                         = "${local.prefix}-public-client-ip-${count.index}"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.nomad_multicloud.name}"
  allocation_method            = "Static"
  sku                          = "Standard"
}

resource "azurerm_network_interface" "public_client_ni" {
  count                     = "${var.azure_public_client_count}"
  name                      = "${local.prefix}-public-client-ni-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.nomad_multicloud.name}"

  ip_configuration {
    name                          = "${local.prefix}-public-client-ipc"
    subnet_id                     = "${azurerm_subnet.public_clients_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.public_client_public_ip.*.id, count.index)}"
  }
}