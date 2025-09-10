
output "nomad_UI" {
  value = "https://${aws_instance.server[0].public_ip}:4646"
}

output "nomad_management_token" {
  value = random_uuid.nomad_mgmt_token.result
  sensitive = false
}