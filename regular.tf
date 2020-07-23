resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_compute_network" "main" {
  name                    = "cft-gke-test-${random_string.suffix.result}"
  auto_create_subnetworks = false
  project         = var.project_id
}

resource "google_compute_subnetwork" "main" {
  name          = "cft-gke-test-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/17"
  region        = var.region
  network       = google_compute_network.main.self_link
  project         = var.project_id

  secondary_ip_range {
    range_name    = "cft-gke-test-pods-${random_string.suffix.result}"
    ip_cidr_range = "192.168.0.0/18"
  }

  secondary_ip_range {
    range_name    = "cft-gke-test-services-${random_string.suffix.result}"
    ip_cidr_range = "192.168.64.0/18"
  }
}

module "gke-dev-regular" {
  source             = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version            = "~> 10.0"
  project_id         = var.project_id
  name               = "test-cluster-reg"
  region             = var.region
  network            = google_compute_network.main.name
  subnetwork         = google_compute_subnetwork.main.name
  ip_range_pods      = google_compute_subnetwork.main.secondary_ip_range[0].range_name
  ip_range_services  = google_compute_subnetwork.main.secondary_ip_range[1].range_name
  create_service_account     = true
  add_cluster_firewall_rules = false
}