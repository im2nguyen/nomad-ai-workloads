data "aws_ami" "ubuntu-jammy-2204" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#-------------------------------------------------------------------------------
# Nomad Server(s)
#-------------------------------------------------------------------------------

resource "aws_instance" "server" {

  depends_on             = [module.vpc]
  count                  = var.aws_server_count

  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_server_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.nomad_ui_ingress.id, 
    aws_security_group.ssh_ingress.id, 
    aws_security_group.allow_all_internal.id,
    aws_security_group.external_client_ingress.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-server-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "server"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}/shared/data-scripts/user-data-server.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    server_count            = "${var.aws_server_count}"
    cloud_env               = "aws"
    retry_join              = local.retry_join_nomad,
    nomad_node_name         = "aws-server-${count.index}"
    nomad_encryption_key    = random_id.nomad_gossip_key.b64_std
    nomad_management_token  = random_uuid.nomad_mgmt_token.result
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.server_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.server_key[count.index].private_key_pem}")
  })

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.vm_ssh_key.private_key_pem
    host        = self.public_ip
  }

  # Waits for cloud-init to complete. Needed for ACL creation.
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for user data script to finish'",
      "cloud-init status --wait > /dev/null"
    ]
  }

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

#-------------------------------------------------------------------------------
# Nomad Client(s)
#-------------------------------------------------------------------------------

resource "aws_instance" "small_private_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_small_private_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_small_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-small-private-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "small"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-small-private-client-${count.index}"
    nomad_agent_meta        = "isPublic = false, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.small_private_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.small_private_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "small_public_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_small_public_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_small_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.public_client_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-small-public-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "small"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-small-public-client-${count.index}"
    nomad_agent_meta        = "isPublic = true, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.small_public_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.small_public_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "medium_private_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_medium_private_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_medium_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-medium-private-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "medium"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-medium-private-client-${count.index}"
    nomad_agent_meta        = "isPublic = false, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.medium_private_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.medium_private_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "medium_public_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_medium_public_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_medium_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.public_client_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-medium-public-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "medium"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-medium-public-client-${count.index}"
    nomad_agent_meta        = "isPublic = true, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.medium_public_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.medium_public_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "large_private_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_large_private_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_large_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-large-private-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "large"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-large-private-client-${count.index}"
    nomad_agent_meta        = "isPublic = false, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.large_private_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.large_private_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "large_public_client" {
  
  # depends_on             = [aws_instance.server]
  count                  = var.aws_large_public_client_count
  
  # ami                    = var.aws_ami
  ami                    = data.aws_ami.ubuntu-jammy-2204.id
  instance_type          = var.aws_large_instance_type
  key_name               = aws_key_pair.vm_ssh_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.public_client_ingress.id,
    aws_security_group.allow_all_internal.id
  ]
  subnet_id = module.vpc.public_subnets[0]

  # NomadJoinTag is necessary for nodes to automatically join the cluster
  tags = {
    Name = "${local.prefix}-large-public-client-${count.index}",
    NomadJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType = "client"
  } 

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.aws_root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}//shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    cloud_env               = "aws"
    node_pool               = "large"
    retry_join              = local.retry_join_nomad
    nomad_node_name         = "aws-large-public-client-${count.index}"
    nomad_agent_meta        = "isPublic = true, cloud = \"aws\""
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.large_public_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.large_public_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}