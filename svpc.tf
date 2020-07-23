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

resource "google_service_account" "node-sa" {
  project      = var.project_id
  account_id   = "node-sa"
  display_name = "node-sa"
}

resource "google_compute_subnetwork_iam_member" "subnet" {
  subnetwork = var.subnetwork
  project = var.network_project_id
  role       = "roles/compute.networkUser"
  member =  "serviceAccount:${google_service_account.node-sa.email}"
  region = var.region
}

module "gke-dev-8" {
  source             = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version            = "~> 10.0"
  project_id         = var.project_id
  name               = "test-cluster-svpc-new"
  region             = var.region
  network_project_id = var.network_project_id
  network            = var.network
  subnetwork         = var.subnetwork
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services
  master_ipv4_cidr_block     = "10.0.0.0/28"
  create_service_account     = false
  service_account            = can(google_compute_subnetwork_iam_member.subnet.etag) ? google_service_account.node-sa.email : ""
  add_cluster_firewall_rules = true
}