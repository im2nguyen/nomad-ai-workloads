
# Azure private client keys
resource "tls_private_key" "azure_client_key" {
  count       = "${var.azure_private_client_count}"
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Azure private client CSR
resource "tls_cert_request" "azure_client_csr" {
  count = "${var.azure_private_client_count}"
  private_key_pem = "${element(tls_private_key.azure_client_key.*.private_key_pem, count.index)}"

  subject {
    country = "US"
    province = "CA"
    locality = "San Francisco/street=101 Second Street/postalCode=9410"
    organization = "HashiCorp Inc."
    organizational_unit = "Runtime"
    common_name  = "client-${count.index}.${var.datacenter}.${var.domain}"
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

# Azure private client certs
resource "tls_locally_signed_cert" "azure_client_cert" {
  count = "${var.azure_private_client_count}"
  cert_request_pem = "${element(tls_cert_request.azure_client_csr.*.cert_request_pem, count.index)}"

  ca_private_key_pem = "${tls_private_key.datacenter_ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.datacenter_ca.cert_pem}"

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}


# Azure public client keys
resource "tls_private_key" "azure_public_client_key" {
  count       = "${var.azure_public_client_count}"
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Azure public client CSR
resource "tls_cert_request" "azure_public_client_csr" {
  count = "${var.azure_public_client_count}"
  private_key_pem = "${element(tls_private_key.azure_public_client_key.*.private_key_pem, count.index)}"

  subject {
    country = "US"
    province = "CA"
    locality = "San Francisco/street=101 Second Street/postalCode=9410"
    organization = "HashiCorp Inc."
    organizational_unit = "Runtime"
    common_name  = "client-${count.index}.${var.datacenter}.${var.domain}"
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

# Azure public client certs
resource "tls_locally_signed_cert" "azure_public_client_cert" {
  count = "${var.azure_public_client_count}"
  cert_request_pem = "${element(tls_cert_request.azure_public_client_csr.*.cert_request_pem, count.index)}"

  ca_private_key_pem = "${tls_private_key.datacenter_ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.datacenter_ca.cert_pem}"

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}