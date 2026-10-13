# GKE Standard cluster modelled on cluster123:
# regional control plane in us-central1, nodes in us-central1-a, REGULAR channel,
# VPC-native on the default network, shielded nodes, Managed Prometheus.

resource "google_project_service" "container" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_container_cluster" "this" {
  name           = var.cluster_name
  location       = var.region
  node_locations = var.node_locations

  network    = var.network
  subnetwork = var.subnetwork

  # Manage nodes in a separate node pool resource (below) so it can change
  # without recreating the cluster.
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = var.deletion_protection

  release_channel {
    channel = var.release_channel
  }

  # VPC-native; GKE creates the Pod and Service secondary ranges automatically.
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  enable_shielded_nodes = true

  addons_config {
    http_load_balancing {
      disabled = false # GKE Ingress controller
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    dns_cache_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "STORAGE", "HPA", "POD", "DAEMONSET", "DEPLOYMENT", "STATEFULSET", "CADVISOR", "KUBELET"]

    managed_prometheus {
      enabled = true
    }
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_DISABLED"
  }

  depends_on = [google_project_service.container]
}

resource "google_container_node_pool" "default" {
  name           = "default-pool"
  cluster        = google_container_cluster.this.id
  node_locations = var.node_locations
  node_count     = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy  = "SURGE"
    max_surge = 1
  }

  node_config {
    machine_type = var.machine_type
    disk_type    = var.disk_type
    disk_size_gb = var.disk_size_gb
    image_type   = "COS_CONTAINERD"

    # Same as cluster123: Compute Engine default service account with the
    # standard GKE scopes (devstorage.read_only lets nodes pull from Artifact Registry).
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    shielded_instance_config {
      enable_integrity_monitoring = true
    }
  }
}
