#!/usr/bin/env bash
# One-time Google Cloud setup for the pipelines in buvananaji/GKEAutomation.
# Bash version of bootstrap-ci.ps1, for Google Cloud Shell. Run as a project Owner:
#   bash bootstrap-ci.sh
#
# Creates:
#   - gs://test1-project-234813-tfstate   Terraform state (versioned, private)
#   - terraform-ci service account        identity the Terraform pipeline runs as
#   - gke-deployer service account        identity the Applications pipeline runs as
#   - WIF provider "gkeautomation"        lets ONLY this repo's workflows act as these accounts (no keys)
# Safe to re-run: steps that already exist are skipped.
set -euo pipefail

P=test1-project-234813
PN=782667784224
REPO=buvananaji/GKEAutomation
BUCKET=gs://$P-tfstate
TF_SA=terraform-ci@$P.iam.gserviceaccount.com
DEPLOY_SA=gke-deployer@$P.iam.gserviceaccount.com
PRINCIPAL="principalSet://iam.googleapis.com/projects/$PN/locations/global/workloadIdentityPools/github/attribute.repository/$REPO"

gcloud config set project "$P" >/dev/null
gcloud services enable iamcredentials.googleapis.com sts.googleapis.com container.googleapis.com artifactregistry.googleapis.com

echo "== State bucket"
gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1 || \
  gcloud storage buckets create "$BUCKET" --location us-central1 --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update "$BUCKET" --versioning

echo "== Service accounts"
gcloud iam service-accounts describe "$TF_SA" >/dev/null 2>&1 || \
  gcloud iam service-accounts create terraform-ci --display-name "Terraform CI (GKEAutomation)"
gcloud iam service-accounts describe "$DEPLOY_SA" >/dev/null 2>&1 || \
  gcloud iam service-accounts create gke-deployer --display-name "GKE app deployer (GKEAutomation)"

echo "== terraform-ci roles"
for role in roles/container.admin roles/artifactregistry.admin roles/serviceusage.serviceUsageAdmin roles/compute.networkViewer roles/compute.publicIpAdmin; do
  gcloud projects add-iam-policy-binding "$P" --member "serviceAccount:$TF_SA" --role "$role" --condition=None --format=none
done
gcloud storage buckets add-iam-policy-binding "$BUCKET" --member "serviceAccount:$TF_SA" --role roles/storage.objectAdmin --format=none
gcloud iam service-accounts add-iam-policy-binding "$PN-compute@developer.gserviceaccount.com" \
  --member "serviceAccount:$TF_SA" --role roles/iam.serviceAccountUser --format=none

echo "== gke-deployer roles"
for role in roles/artifactregistry.writer roles/container.developer; do
  gcloud projects add-iam-policy-binding "$P" --member "serviceAccount:$DEPLOY_SA" --role "$role" --condition=None --format=none
done

echo "== Workload Identity Federation provider for $REPO"
gcloud iam workload-identity-pools providers describe gkeautomation --location global --workload-identity-pool github >/dev/null 2>&1 || \
  gcloud iam workload-identity-pools providers create-oidc gkeautomation --location global \
    --workload-identity-pool github --display-name "GitHub GKEAutomation" \
    --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition "assertion.repository=='$REPO'"

for sa in "$TF_SA" "$DEPLOY_SA"; do
  gcloud iam service-accounts add-iam-policy-binding "$sa" --role roles/iam.workloadIdentityUser --member "$PRINCIPAL" --format=none
done

echo
echo "Done. GitHub secrets for $REPO (already set):"
echo "  GCP_WIF_PROVIDER = projects/$PN/locations/global/workloadIdentityPools/github/providers/gkeautomation"
echo "  GCP_TERRAFORM_SA = $TF_SA"
echo "  GCP_DEPLOYER_SA  = $DEPLOY_SA"
