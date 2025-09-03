#-------------------------------------------------------------------------------
# Local Values
#-------------------------------------------------------------------------------

locals {
  # Create individual instance configurations
  client_instances = [
    for i in range(var.count) : {
      index              = i
      nomad_node_name    = "aws-${var.size}-${var.public ? "public" : "private"}-client-${i}"
      nomad_agent_meta   = "isPublic = ${var.public}, cloud = \"aws\""
      security_groups    = var.public ? [
        var.security_group_ids.ssh_ingress,
        var.security_group_ids.public_client_ingress,
        var.security_group_ids.allow_all_internal
      ] : [
        var.security_group_ids.ssh_ingress,
        var.security_group_ids.allow_all_internal
      ]
    }
  ]
}

#-------------------------------------------------------------------------------
# TLS Certificates
#-------------------------------------------------------------------------------

# Client private keys
resource "tls_private_key" "client_key" {
  count       = var.count
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Client certificate signing requests
resource "tls_cert_request" "client_csr" {
  count = var.count
  private_key_pem = tls_private_key.client_key[count.index].private_key_pem

  subject {
    country             = "US"
    province            = "CA"
    locality            = "San Francisco/street=101 Second Street/postalCode=9410"
    organization        = "HashiCorp Inc."
    organizational_unit = "Runtime"
    common_name         = "client-${count.index}.${var.datacenter}.${var.domain}"
  }

  dns_names = [
    "client.${var.datacenter}.${var.domain}",
    "client-${count.index}.${var.datacenter}.${var.domain}",
    "nomad-client-${count.index}.${var.datacenter}.${var.domain}",
    "client.global.nomad",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]
}

# Client certificates
resource "tls_locally_signed_cert" "client_cert" {
  count = var.count
  cert_request_pem = tls_cert_request.client_csr[count.index].cert_request_pem

  ca_private_key_pem = var.ca_private_key
  ca_cert_pem        = var.ca_certificate

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

#-------------------------------------------------------------------------------
# AWS Instances
#-------------------------------------------------------------------------------

resource "aws_instance" "nomad_clients" {
  count = var.count
  
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = local.client_instances[count.index].security_groups
  subnet_id              = var.public_subnet_ids[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${var.prefix}-${var.size}-${var.public ? "public" : "private"}-client-${count.index}"
    NomadJoinTag = "auto-join-${var.suffix}"
    NomadType = "client"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = var.ebs_block_device_size
    delete_on_termination = "true"
  }

  user_data = templatefile(var.user_data_script_path, {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = var.size
    retry_join              = var.retry_join
    nomad_node_name         = local.client_instances[count.index].nomad_node_name
    nomad_agent_meta        = local.client_instances[count.index].nomad_agent_meta
    ca_certificate          = base64gzip(var.ca_certificate)
    agent_certificate       = base64gzip(tls_locally_signed_cert.client_cert[count.index].cert_pem)
    agent_key               = base64gzip(tls_private_key.client_key[count.index].private_key_pem)
  })

  iam_instance_profile = var.iam_instance_profile_name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}
