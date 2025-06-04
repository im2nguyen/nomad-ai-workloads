resource "azurerm_linux_virtual_machine" "client" {
  name                  = "hashistack-client-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.hashistack.name}"
  network_interface_ids = ["${element(azurerm_network_interface.hashistack-client-ni.*.id, count.index)}"]
  size                  = "${var.azure_client_instance_type}"
  count                 = "${var.azure_client_count}"
  # Depends on AWS server(s)
  depends_on             = [aws_instance.server]

  source_image_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/images/${var.image_name}"

  os_disk {
    name              = "hashistack-client-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "hashistack-client-${count.index}"
  admin_username = "ubuntu"
  admin_password = random_string.vm_password.result
  custom_data    = "${base64encode(templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
      domain                  = var.domain
      datacenter              = var.datacenter
      nomad_node_name         = "azure-client-${count.index}"
      nomad_agent_meta        = "isPublic = false, cloud = \"azure\""
      region                  = var.location
      cloud_env               = "azure"
      node_pool               = "azure"
      retry_join              = local.retry_join
      nomad_binary            = var.nomad_binary
      ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
      agent_certificate       = base64gzip("${tls_locally_signed_cert.azure_client_cert[count.index].cert_pem}")
      agent_key               = base64gzip("${tls_private_key.azure_client_key[count.index].private_key_pem}")
  }))}"
  
  disable_password_authentication = false
}

locals {
  retry_join = "${join(",", aws_instance.server[*].public_ip)}"
}