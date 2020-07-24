/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cluster_name = "test-cluster-svpc"
  bastion_name = format("%s-bastion", local.cluster_name)
  bastion_zone = format("%s-a", var.region)
}

# bastion host
data "template_file" "startup_script" {
  template = <<-EOF
  sudo apt-get update -y
  sudo apt-get install -y tinyproxy
  EOF
}

data "google_compute_subnetwork" "subnetwork" {
  name    = var.subnetwork
  project = var.network_project_id
  region  = var.region
}

module "bastion" {
  source         = "terraform-google-modules/bastion-host/google"
  version        = "~> 2.0"
  network        = var.network
  subnet         = data.google_compute_subnetwork.subnetwork.self_link
  project        = var.project_id
  host_project   = var.network_project_id
  name           = local.bastion_name
  zone           = local.bastion_zone
  image_project  = "debian-cloud"
  image_family   = "debian-9"
  machine_type   = "g1-small"
  startup_script = data.template_file.startup_script.rendered
  members        = [var.bastion_member]
  shielded_vm    = "false"
  tags           = ["egress-internet"]
}

# fw for bastion packages
resource "google_compute_firewall" "bastion-fw" {
  name      = "bastion-fw"
  network   = var.network
  project   = var.network_project_id
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_service_accounts = [module.bastion.service_account]
}

# fw for svc lb
resource "google_compute_firewall" "lb-fw" {
  name          = "lb-fw"
  network       = var.network
  project       = var.network_project_id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

}

# node sa
resource "google_service_account" "node-sa" {
  project      = var.project_id
  account_id   = "node-sa"
  display_name = "node-sa"
}

resource "google_compute_subnetwork_iam_member" "subnet" {
  subnetwork = var.subnetwork
  project    = var.network_project_id
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.node-sa.email}"
  region     = var.region
}

# gke
module "gke-dev-9" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "~> 10.0"
  project_id                 = var.project_id
  name                       = local.cluster_name
  region                     = var.region
  network_project_id         = var.network_project_id
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  master_ipv4_cidr_block     = "172.16.0.0/28"
  create_service_account     = false
  service_account            = can(google_compute_subnetwork_iam_member.subnet.etag) ? google_service_account.node-sa.email : ""
  add_cluster_firewall_rules = true
  enable_private_endpoint    = true
  enable_private_nodes       = true
  node_pools_tags = {
    all = ["allow-lb"]
  }
  master_authorized_networks = [{
    cidr_block   = "${module.bastion.ip_address}/32"
    display_name = "Bastion Host"
  }]
}