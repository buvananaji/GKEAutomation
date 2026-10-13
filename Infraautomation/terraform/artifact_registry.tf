# Docker repository in Artifact Registry (the successor to Google Container Registry).
# Images: <region>-docker.pkg.dev/<project>/docker-repotest/<image>:<tag>

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "docker" {
  repository_id = var.registry_name
  location      = var.region
  format        = "DOCKER"
  description   = "Docker images for ${var.cluster_name}"

  depends_on = [google_project_service.artifactregistry]
}
