resource "google_compute_network" "nomad-multicloud" {
  name = "nomad-multicloud-${var.name_prefix}"
}

resource "google_compute_firewall" "ssh_ingress" {
  name          = "${var.name_prefix}-ssh-ingress"
  network       = google_compute_network.nomad-multicloud.name
  source_ranges = [var.allowlist_ip]

  # SSH
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "allow_all_internal" {
  name        = "${var.name_prefix}-allow-all-internal"
  network     = google_compute_network.nomad-multicloud.name
  source_tags = ["auto-join"]

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

resource "google_compute_firewall" "clients_ingress" {
  name          = "${var.name_prefix}-clients-ingress"
  network       = google_compute_network.nomad-multicloud.name
  source_ranges = [var.allowlist_ip]
  target_tags   = ["nomad-clients"]

  # Add application ingress rules here
  # These rules are applied only to the client nodes

  # nginx example; replace with your application port
  allow {
    protocol = "tcp"
    ports    = [80]
  }
}