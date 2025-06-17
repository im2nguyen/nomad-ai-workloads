# output "debug_azure_vm_password" {
#   value = random_string.vm_password.result
# }

# output "debug_azure_private_ssh_command" {
#     value = "ssh ubuntu@${azurerm_linux_virtual_machine.private_client[0].public_ip_address}"
# }

# output "debug_azure_public_ssh_command" {
#     value = "ssh ubuntu@${azurerm_linux_virtual_machine.public_client[0].public_ip_address}"
# }

# output "debug_retry_join" {
#     value = aws_instance.server[*].public_ip
# }