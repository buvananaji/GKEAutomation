# One-time Google Cloud setup for the Terraform pipeline in buvananaji/GKEAutomation.
# Run as a project Owner:  powershell -ExecutionPolicy Bypass -File .\bootstrap-ci.ps1
#
# Creates:
#   - gs://test1-project-234813-tfstate   Terraform state (versioned, private)
#   - terraform-ci service account        identity the pipeline runs as
#   - WIF provider "gkeautomation"        lets ONLY this repo's workflows act as terraform-ci (no keys)

$ErrorActionPreference = "Stop"
$gcloud  = "C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$Account = "buvananaji@gmail.com"
$P       = "test1-project-234813"
$PN      = "782667784224"
$Repo    = "buvananaji/GKEAutomation"
$Bucket  = "gs://$P-tfstate"
$SA      = "terraform-ci@$P.iam.gserviceaccount.com"

function Invoke-Gcloud { & $gcloud @args --account=$Account; if ($LASTEXITCODE -ne 0) { throw "gcloud failed: $args" } }

Write-Host "== State bucket"
Invoke-Gcloud storage buckets create $Bucket --project $P --location us-central1 --uniform-bucket-level-access --public-access-prevention
Invoke-Gcloud storage buckets update $Bucket --versioning

Write-Host "== Service account"
Invoke-Gcloud iam service-accounts create terraform-ci --project $P --display-name "Terraform CI (GKEAutomation)"

Write-Host "== Project roles (what Terraform manages: GKE, Artifact Registry, APIs)"
foreach ($role in "roles/container.admin", "roles/artifactregistry.admin", "roles/serviceusage.serviceUsageAdmin", "roles/compute.networkViewer") {
  Invoke-Gcloud projects add-iam-policy-binding $P --member "serviceAccount:$SA" --role $role --condition=None --format=none
}

Write-Host "== State bucket access"
Invoke-Gcloud storage buckets add-iam-policy-binding $Bucket --member "serviceAccount:$SA" --role roles/storage.objectAdmin --format=none

Write-Host "== Allow terraform-ci to give nodes the Compute Engine default service account"
Invoke-Gcloud iam service-accounts add-iam-policy-binding "$PN-compute@developer.gserviceaccount.com" --project $P --member "serviceAccount:$SA" --role roles/iam.serviceAccountUser --format=none

Write-Host "== Workload Identity Federation provider for $Repo"
Invoke-Gcloud iam workload-identity-pools providers create-oidc gkeautomation --project $P --location global `
  --workload-identity-pool github --display-name "GitHub GKEAutomation" `
  --issuer-uri "https://token.actions.githubusercontent.com" `
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" `
  --attribute-condition "assertion.repository=='$Repo'"

Invoke-Gcloud iam service-accounts add-iam-policy-binding $SA --project $P --role roles/iam.workloadIdentityUser `
  --member "principalSet://iam.googleapis.com/projects/$PN/locations/global/workloadIdentityPools/github/attribute.repository/$Repo" --format=none

Write-Host ""
Write-Host "Done. GitHub secrets for ${Repo}:"
Write-Host "  GCP_WIF_PROVIDER = projects/$PN/locations/global/workloadIdentityPools/github/providers/gkeautomation"
Write-Host "  GCP_TERRAFORM_SA = $SA"
