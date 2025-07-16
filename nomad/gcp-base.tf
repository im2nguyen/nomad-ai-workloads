resource "google_compute_network" "nomad_multicloud" {
  name = "${local.prefix}-network"
}

resource "google_compute_firewall" "ssh_ingress" {
  name          = "${local.prefix}-ssh-ingress"
  network       = google_compute_network.nomad_multicloud.name
  source_ranges = [var.allowlist_ip]
  target_tags   = ["nomad-client"]

  # SSH
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_all_internal" {
  name        = "${local.prefix}-allow-all-internal"
  network     = google_compute_network.nomad_multicloud.name
  source_tags = ["nomad-client"]
  target_tags = ["nomad-client"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "public_client_ingress" {
  name          = "${local.prefix}-public-client-ingress"
  network       = google_compute_network.nomad_multicloud.name
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nomad-public-client"]

  # HTTP
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Secondary application port
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}