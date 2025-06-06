locals {
  retry_join = "${join(",", aws_instance.server[*].public_ip)}"
}

# Private client nodes

resource "azurerm_linux_virtual_machine" "private_client" {
  name                  = "${local.prefix}-private-client-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${data.azurerm_resource_group.nomad_multicloud.name}"
  network_interface_ids = ["${element(azurerm_network_interface.private_client_ni.*.id, count.index)}"]
  size                  = "${var.azure_client_instance_type}"
  count                 = "${var.azure_private_client_count}"
  # Depends on AWS server(s)
  depends_on             = [aws_instance.server]

  source_image_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.azure_resource_group_name}/providers/Microsoft.Compute/images/${var.azure_image_name}"

  os_disk {
    name              = "${local.prefix}-private0client-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "${local.prefix}-client-${count.index}"
  admin_username = "ubuntu"
  admin_password = random_string.vm_password.result
  custom_data    = "${base64encode(templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
      domain                  = var.domain
      datacenter              = var.datacenter
      nomad_node_name         = "azure-client-${count.index}"
      nomad_agent_meta        = "isPublic = false, cloud = \"azure\""
      region                  = var.azure_location
      cloud_env               = "azure"
      node_pool               = "azure"
      retry_join              = local.retry_join
      ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
      agent_certificate       = base64gzip("${tls_locally_signed_cert.azure_client_cert[count.index].cert_pem}")
      agent_key               = base64gzip("${tls_private_key.azure_client_key[count.index].private_key_pem}")
  }))}"
  
  disable_password_authentication = false
}

# Public client nodes

resource "azurerm_linux_virtual_machine" "public_client" {
  name                  = "${local.prefix}-public-client-${count.index}"
  location              = "${var.azure_location}"
  resource_group_name   = "${data.azurerm_resource_group.nomad_multicloud.name}"
  network_interface_ids = ["${element(azurerm_network_interface.public_client_ni.*.id, count.index)}"]
  size                  = "${var.azure_client_instance_type}"
  count                 = "${var.azure_public_client_count}"
  # Depends on AWS server(s)
  depends_on             = [aws_instance.server]

  source_image_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.azure_resource_group_name}/providers/Microsoft.Compute/images/${var.azure_image_name}"

  os_disk {
    name              = "${local.prefix}-public-client-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "${local.prefix}-client-${count.index}"
  admin_username = "ubuntu"
  admin_password = random_string.vm_password.result
  custom_data    = "${base64encode(templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
      domain                  = var.domain
      datacenter              = var.datacenter
      nomad_node_name         = "azure-public-client-${count.index}"
      nomad_agent_meta        = "isPublic = true, cloud = \"azure\""
      region                  = var.azure_location
      cloud_env               = "azure"
      node_pool               = "azure"
      retry_join              = local.retry_join
      ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
      agent_certificate       = base64gzip("${tls_locally_signed_cert.azure_public_client_cert[count.index].cert_pem}")
      agent_key               = base64gzip("${tls_private_key.azure_public_client_key[count.index].private_key_pem}")
  }))}"
  
  disable_password_authentication = false
}