# testcluster + docker-repotest (Terraform)

Creates in project `test1-project-234813`:

| Resource | Name | Notes |
|---|---|---|
| GKE Standard cluster | `testcluster` | Same settings as `cluster123` (see below) |
| Node pool | `default-pool` | 2 × `e2-medium`, 100 GB `pd-standard`, COS_CONTAINERD |
| Artifact Registry (Docker) | `docker-repotest` | `us-central1-docker.pkg.dev/test1-project-234813/docker-repotest` |
| APIs | container, artifactregistry | Enabled if not already |

## Settings copied from cluster123

- Regional control plane in `us-central1`, nodes only in `us-central1-a`
- REGULAR release channel
- VPC-native on the `default` network/subnet (Pod/Service ranges auto-created)
- Shielded nodes, integrity monitoring, legacy metadata endpoints disabled
- HTTP Load Balancing (GKE Ingress), NodeLocal DNSCache, PD CSI driver
- Logging: system + workloads; Monitoring: system components + Managed Prometheus
- Security posture BASIC, vulnerability scanning off
- Nodes use the Compute Engine default service account with standard GKE scopes
- Auto-repair, auto-upgrade, surge upgrades (max surge 1)

Differences: the node pool is a separate Terraform resource (best practice), and
`deletion_protection` is on.

## Usage

```bash
cd Infraautomation/terraform
gcloud auth application-default login   # once, as an account with Owner/Editor
terraform init
terraform plan
terraform apply
```

Then connect kubectl (also printed as the `get_credentials_command` output):

```bash
gcloud container clusters get-credentials testcluster --region us-central1 --project test1-project-234813
```

## Cost

Like cluster123, this runs 2 × e2-medium nodes 24/7 plus the GKE cluster
management fee (the free tier covers one zonal/Autopilot cluster per billing
account, so a second cluster is usually billed).

## Destroy

`deletion_protection` blocks accidental deletes. To remove everything:

```bash
terraform apply -var deletion_protection=false
terraform destroy
```
