terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }

  # Remote state shared by the GitHub Actions pipeline and local runs.
  # The bucket is created by Infraautomation/setup/bootstrap-ci.ps1.
  backend "gcs" {
    bucket = "test1-project-234813-tfstate"
    prefix = "gke/testcluster"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
