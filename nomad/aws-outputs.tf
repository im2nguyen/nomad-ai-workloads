# Exports all needed environment variables to connect to Nomad 
# datacenter using CLI commands
resource "local_file" "environment_variables" {
  filename = "datacenter.env"
  content = <<-EOT
    export NOMAD_ADDR="https://${aws_instance.server[0].public_ip}:4646"
    export NOMAD_TOKEN="${random_uuid.nomad_mgmt_token.result}"
    export NOMAD_CACERT="${path.cwd}/certs/datacenter_ca.cert"
    export NOMAD_TLS_SERVER_NAME="nomad.${var.datacenter}.${var.domain}"
  EOT
}

output "configure-local-environment" {
  value = "source ./datacenter.env"
}

output "nomad_UI" {
  value = "https://${aws_instance.server[0].public_ip}:4646"
}

output "nomad_management_token" {
  value = random_uuid.nomad_mgmt_token.result
  sensitive = false
}

output "nomad_user_token" {
  value = nonsensitive(nomad_acl_token.nomad-user-token.secret_id)
}

# output "debug_aws_server_ssh" {
#   value = "ssh -i certs/aws-key-pair.pem ubuntu@${aws_instance.server[0].public_ip}"
# }

# output "debug_aws_client_ssh" {
#   value = "ssh -i certs/aws-key-pair.pem ubuntu@${aws_instance.client[0].public_ip}"
# }