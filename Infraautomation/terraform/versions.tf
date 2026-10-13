terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Remote state (recommended once more than one person or CI runs Terraform).
  # Create the bucket first, then uncomment and run `terraform init -migrate-state`.
  # backend "gcs" {
  #   bucket = "test1-project-234813-tfstate"
  #   prefix = "gke/testcluster"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
