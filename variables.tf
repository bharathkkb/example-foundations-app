

variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "region" {
  description = "The region to host the cluster in"
  default = "us-west1"
}

variable "network_project_id" {
  description = "The project ID to host the cluster in"
}

variable "network" {
  description = "The VPC network to host the cluster in"
  default     = "vpc-d-shared-private"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  default     = "sb-d-shared-private-us-west1"
}

variable "ip_range_pods" {
  description = "The secondary ip range to use for pods"
  default     = "rn-d-shared-private-us-west1-gke-pod"
}

variable "ip_range_services" {
  description = "The secondary ip range to use for services"
  default     = "rn-d-shared-private-us-west1-gke-svc"
}
