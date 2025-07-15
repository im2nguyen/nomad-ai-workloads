locals {
  gcp_retry_join = "${join(",", aws_instance.server[*].public_ip)}"
}

# Private client node

resource "google_compute_instance" "private_client" {
  count        = var.gcp_private_client_count
  name         = "${local.prefix}-client-${count.index}"
  machine_type = var.gcp_client_instance_type
  zone         = var.gcp_zone
  tags         = ["nomad-client"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      # image = var.gcp_machine_image
      image = "ubuntu-minimal-2204-jammy-v20231213b"
      size  = var.gcp_root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.nomad_multicloud.name
    access_config {
      // Leave empty to get an ephemeral public IP
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    nomad_node_name         = "gcp-client-${count.index}"
    nomad_agent_meta        = "isPublic = false, cloud = \"gcp\""
    region                  = var.gcp_region
    cloud_env               = "gce"
    node_pool               = "default"
    retry_join              = local.gcp_retry_join
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.gcp_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.gcp_client_key[count.index].private_key_pem}")
  })
}

# Public client node

resource "google_compute_instance" "public_client" {
  count        = var.gcp_public_client_count
  name         = "${local.prefix}-public-client-${count.index}"
  machine_type = var.gcp_client_instance_type
  zone         = var.gcp_zone
  tags         = ["nomad-client","nomad-public-client"]

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      # image = var.gcp_machine_image
      image = "ubuntu-minimal-2204-jammy-v20231213b"
      size  = var.gcp_root_block_device_size
    }
  }

  network_interface {
    network = google_compute_network.nomad_multicloud.name
    access_config {
      // Leave empty to get an ephemeral public IP
    }
  }

  service_account {
    # https://developers.google.com/identity/protocols/googlescopes
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
    ]
  }

  metadata_startup_script = templatefile("${path.module}/../shared/data-scripts/user-data-client.sh", {
    domain                  = var.domain
    datacenter              = var.datacenter
    nomad_node_name         = "gcp-public-client-${count.index}"
    nomad_agent_meta        = "isPublic = true, cloud = \"gcp\""
    region                  = var.gcp_region
    cloud_env               = "gce"
    node_pool               = "default"
    retry_join              = local.gcp_retry_join
    ca_certificate          = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}")
    agent_certificate       = base64gzip("${tls_locally_signed_cert.gcp_public_client_cert[count.index].cert_pem}")
    agent_key               = base64gzip("${tls_private_key.gcp_public_client_key[count.index].private_key_pem}")
  })
}