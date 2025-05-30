# output "debug_azure_vm_password" {
#   value = random_string.vm_password.result
# }

# output "debug_azure_ssh_command" {
#     value = "ssh ubuntu@${azurerm_linux_virtual_machine.client[0].public_ip_address}"
# }

# output "debug_retry_join" {
#     value = aws_instance.server[*].public_ip
# }