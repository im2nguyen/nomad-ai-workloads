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

data "azurerm_resource_group" "hashistack" {
  name = "hashistack"
}

resource "azurerm_virtual_network" "hashistack-vn" {
  name                = "hashistack-vn"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.hashistack.name}"
}

resource "azurerm_subnet" "hashistack-sn" {
  name                 = "hashistack-sn"
  resource_group_name  = "${data.azurerm_resource_group.hashistack.name}"
  virtual_network_name = "${azurerm_virtual_network.hashistack-vn.name}"
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "hashistack-sg" {
  name                = "hashistack-sg"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.hashistack.name}"
}

resource "azurerm_subnet_network_security_group_association" "hashistack-sg-association" {
  subnet_id                 = azurerm_subnet.hashistack-sn.id
  network_security_group_id = azurerm_network_security_group.hashistack-sg.id
}

resource "azurerm_network_security_rule" "client_ports" {
  name                        = "${var.name_prefix}-client-ports"
  resource_group_name         = "${data.azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 105
  direction = "Inbound"
  access    = "Allow"
  protocol  = "*"

  #TODO: remove consul ports
  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_ranges    = ["8300","8301","8302","8500","8501","8502","8503","8600"]
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "client_ports_outbound" {
  name                        = "${var.name_prefix}-client-ports-outbound"
  resource_group_name         = "${data.azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

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
  name                        = "${var.name_prefix}-ssh-ingress"
  resource_group_name         = "${data.azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

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
  name                        = "${var.name_prefix}-clients-ingress"
  resource_group_name         = "${data.azurerm_resource_group.hashistack.name}"
  network_security_group_name = "${azurerm_network_security_group.hashistack-sg.name}"

  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  source_address_prefix      = var.azure_allowlist_ip
  source_port_range          = "*"
  destination_port_range     = "80"
  destination_address_prefixes = azurerm_linux_virtual_machine.client[*].public_ip_address
}

resource "azurerm_public_ip" "hashistack-client-public-ip" {
  count                        = "${var.azure_client_count}"
  name                         = "hashistack-client-ip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${data.azurerm_resource_group.hashistack.name}"
  allocation_method             = "Static"
}

resource "azurerm_network_interface" "hashistack-client-ni" {
  count                     = "${var.azure_client_count}"
  name                      = "hashistack-client-ni-${count.index}"
  location                  = "${var.location}"
  resource_group_name       = "${data.azurerm_resource_group.hashistack.name}"

  ip_configuration {
    name                          = "hashistack-ipc"
    subnet_id                     = "${azurerm_subnet.hashistack-sn.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.hashistack-client-public-ip.*.id, count.index)}"
  }
}