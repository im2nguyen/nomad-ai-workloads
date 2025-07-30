
output "nomad_UI" {
  value = "https://${aws_instance.server[0].public_ip}:4646"
}

output "nomad_management_token" {
  value = random_uuid.nomad_mgmt_token.result
  sensitive = false
}

# output "nomad_user_token" {
#   value = nonsensitive(nomad_acl_token.nomad_user_token.secret_id)
# }

# output "debug_aws_server_ssh" {
#   value = "ssh -i certs/aws-key-pair.pem ubuntu@${aws_instance.server[0].public_ip}"
# }

# output "debug_aws_client_ssh" {
#   value = "ssh -i certs/aws-key-pair.pem ubuntu@${aws_instance.client[0].public_ip}"
# }