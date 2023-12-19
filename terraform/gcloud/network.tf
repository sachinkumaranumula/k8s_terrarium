resource "google_compute_network" "k8s_network" {
  project                 = var.project
  name                    = "vnet-k8s-dev-uscentral1-001"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k8s_subnet" {
  project                  = var.project
  name                     = "snet-k8s-dev-uscentral1-001"
  region                   = var.region
  ip_cidr_range            = var.cidr
  network                  = google_compute_network.k8s_network.self_link
  private_ip_google_access = true
}

# see https://kubernetes.io/docs/reference/networking/ports-and-protocols/
resource "google_compute_firewall" "k8s_firewall_cp" {
  project     = var.project
  name        = "fw-k8s-dev-uscentral1-001"
  network     = google_compute_network.k8s_network.name
  description = "firewall rule for k8s internal communication"
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "ipip"
  }
  source_ranges = [var.cidr]
}

resource "google_compute_router" "k8s_nat_router" {
  project = var.project
  name    = "router-k8s-dev-uscentral1-001"
  region  = var.region
  network = google_compute_network.k8s_network.self_link
}

resource "google_compute_router_nat" "k8s_nat" {
  name                               = "router-nat-k8s-dev-uscentral1-001"
  router                             = google_compute_router.k8s_nat_router.name
  region                             = google_compute_router.k8s_nat_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
