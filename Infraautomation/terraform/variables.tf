variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the cluster control plane and the Artifact Registry repository."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "testcluster"
}

variable "node_locations" {
  description = "Zones the nodes run in. cluster123 uses a single zone of a regional cluster."
  type        = list(string)
  default     = ["us-central1-a"]
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR or STABLE."
  type        = string
  default     = "REGULAR"
}

variable "network" {
  description = "VPC network name."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name in var.region."
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "Nodes per zone in the default node pool."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for the nodes."
  type        = string
  default     = "e2-medium"
}

variable "disk_type" {
  description = "Boot disk type for the nodes."
  type        = string
  default     = "pd-standard"
}

variable "disk_size_gb" {
  description = "Boot disk size for the nodes, in GB."
  type        = number
  default     = 100
}

variable "deletion_protection" {
  description = "Block `terraform destroy` of the cluster. Set to false (and apply) before destroying."
  type        = bool
  default     = true
}

variable "registry_name" {
  description = "Artifact Registry (Docker) repository name."
  type        = string
  default     = "docker-repotest"
}
