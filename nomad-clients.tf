# Small Private Clients
module "nomad_client_small_private" {
  source = "./modules/nomad-client"

  size   = "small"
  public = false
  count  = var.aws_small_private_client_count

  instance_type = var.aws_small_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem

  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}

# Small Public Clients
module "nomad_client_small_public" {
  source = "./modules/nomad-client"

  size   = "small"
  public = true
  count  = var.aws_small_public_client_count

  instance_type = var.aws_small_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem

  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}

# Medium Private Clients
module "nomad_client_medium_private" {
  source = "./modules/nomad-client"

  size   = "medium"
  public = false
  count  = var.aws_medium_private_client_count

  instance_type = var.aws_medium_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem
  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}

# Medium Public Clients
module "nomad_client_medium_public" {
  source = "./modules/nomad-client"

  size   = "medium"
  public = true
  count  = var.aws_medium_public_client_count

  instance_type = var.aws_medium_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem


  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}

# Large Private Clients
module "nomad_client_large_private" {
  source = "./modules/nomad-client"

  size   = "large"
  public = false
  count  = var.aws_large_private_client_count

  instance_type = var.aws_large_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem


  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}

# Large Public Clients
module "nomad_client_large_public" {
  source = "./modules/nomad-client"

  size   = "large"
  public = true
  count  = var.aws_large_public_client_count

  instance_type = var.aws_large_instance_type

  # Infrastructure references
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnets
  security_group_ids = {
    ssh_ingress           = aws_security_group.ssh_ingress.id
    allow_all_internal    = aws_security_group.allow_all_internal.id
    public_client_ingress = aws_security_group.public_client_ingress.id
  }
  iam_instance_profile_name = aws_iam_instance_profile.instance_profile.name
  key_name                  = aws_key_pair.vm_ssh_key_pair.key_name
  ami_id                    = data.aws_ami.ubuntu-jammy-2204.id

  # Nomad configuration
  domain     = var.domain
  datacenter = var.datacenter
  retry_join = local.retry_join_nomad
  prefix     = local.prefix
  suffix     = random_string.suffix.result

  # TLS certificates
  ca_certificate = tls_self_signed_cert.datacenter_ca.cert_pem
  ca_private_key = tls_private_key.datacenter_ca.private_key_pem


  # Storage configuration
  root_block_device_size = var.aws_root_block_device_size
  ebs_block_device_size  = 50

  # User data script
  user_data_script_path = "${path.module}/shared/data-scripts/user-data-client.sh"
}