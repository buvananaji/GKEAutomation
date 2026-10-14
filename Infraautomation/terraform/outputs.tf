output "cluster_name" {
  value = google_container_cluster.this.name
}

output "cluster_location" {
  value = google_container_cluster.this.location
}

output "cluster_endpoint" {
  value     = google_container_cluster.this.endpoint
  sensitive = true
}

output "get_credentials_command" {
  description = "Run this to point kubectl at the new cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${google_container_cluster.this.location} --project ${var.project_id}"
}

output "apps_ingress_ip" {
  description = "Static IP of the apps Ingress (name: apps_ingress_ip_name)."
  value       = google_compute_global_address.apps_ingress.address
}

output "apps_ingress_ip_name" {
  description = "Use in the Ingress annotation kubernetes.io/ingress.global-static-ip-name."
  value       = google_compute_global_address.apps_ingress.name
}

output "registry_url" {
  description = "Prefix for image names pushed to the Docker repository."
  value       = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}
