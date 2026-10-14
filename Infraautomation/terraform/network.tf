# Fixed public IP for the apps' GKE Ingress (global HTTP load balancer).
# Applications/k8s/ingress.yaml selects it by name with the
# kubernetes.io/ingress.global-static-ip-name annotation.
#
# `address` keeps the IP the Ingress already uses: creating the reservation
# promotes that in-use ephemeral IP to static instead of allocating a new one.

resource "google_compute_global_address" "apps_ingress" {
  name         = "${var.cluster_name}-apps-ip"
  description  = "Static IP for the apps Ingress on ${var.cluster_name}"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
  address      = var.apps_ingress_ip

  lifecycle {
    prevent_destroy = true # releasing it would lose the IP for good
  }
}
