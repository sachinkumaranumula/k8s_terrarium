terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

module "bastion-host_iap-tunneling" {
  source  = "terraform-google-modules/bastion-host/google//modules/iap-tunneling"
  version = "6.0.0"

  project          = var.project
  network          = google_compute_network.k8s_network.self_link
  service_accounts = [google_service_account.k8s_sa.email]

  instances = [{
    name = google_compute_instance_from_template.k8s_cp1.name
    zone = var.zone
    },
    {
      name = google_compute_instance_from_template.k8s_worker1.name
      zone = var.zone
  }]

  members = var.members
}
