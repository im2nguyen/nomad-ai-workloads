data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

resource "random_uuid" "nomad_id" {
}

resource "random_uuid" "nomad_token" {
}

resource "random_string" "vm_password" {
  length           = 16
  special          = false
}

data "azurerm_resource_group" "nomad-multicloud" {
  name = "${var.name_prefix}"
}

resource "azurerm_virtual_network" "nomad-multicloud-vn" {
  name                = "${local.prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_location}"
  resource_group_name = "${data.azurerm_resource_group.nomad-multicloud.name}"
}

resource "azurerm_subnet" "nomad-multicloud-sn" {
  name                 = "${local.prefix}-sn"
  resource_group_name  = "${data.azurerm_resource_group.nomad-multicloud.name}"
  virtual_network_name = "${azurerm_virtual_network.nomad-multicloud-vn.name}"
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nomad-multicloud-sg" {
  name                = "${local.prefix}-sg"
  location            = "${var.azure_location}"
  resource_group_name = "${data.azurerm_resource_group.nomad-multicloud.name}"
}

resource "azurerm_subnet_network_security_group_association" "nomad-multicloud-sg-association" {
  subnet_id                 = azurerm_subnet.nomad-multicloud-sn.id
  network_security_group_id = azurerm_network_security_group.nomad-multicloud-sg.id
}

resource "azurerm_network_security_rule" "client_ports_outbound" {
  name                        = "${local.prefix}-client-ports-outbound"
  resource_group_name         = "${data.azurerm_resource_group.nomad-multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.nomad-multicloud-sg.name}"

  priority  = 106
  direction = "Outbound"
  access    = "Allow"
  protocol  = "*"

  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "ssh_ingress" {
  name                        = "${local.prefix}-ssh-ingress"
  resource_group_name         = "${data.azurerm_resource_group.nomad-multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.nomad-multicloud-sg.name}"

  priority  = 100
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "clients_ingress" {
  name                        = "${local.prefix}-clients-ingress"
  resource_group_name         = "${data.azurerm_resource_group.nomad-multicloud.name}"
  network_security_group_name = "${azurerm_network_security_group.nomad-multicloud-sg.name}"

  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_port_range     = "80"
  destination_address_prefix = "*"
}

resource "azurerm_public_ip" "nomad-multicloud-client-public-ip" {
  count                        = "${var.azure_client_count}"
  name                         = "${local.prefix}-client-ip-${count.index}"
  location                     = "${var.azure_location}"
  resource_group_name          = "${data.azurerm_resource_group.nomad-multicloud.name}"
  allocation_method             = "Static"
}

resource "azurerm_network_interface" "nomad-multicloud-client-ni" {
  count                     = "${var.azure_client_count}"
  name                      = "${local.prefix}-client-ni-${count.index}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${data.azurerm_resource_group.nomad-multicloud.name}"

  ip_configuration {
    name                          = "${local.prefix}-ipc"
    subnet_id                     = "${azurerm_subnet.nomad-multicloud-sn.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.nomad-multicloud-client-public-ip.*.id, count.index)}"
  }
}