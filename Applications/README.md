# Applications

Three sample apps deployed to **`testcluster`** (created by `Infraautomation/terraform`)
by `.github/workflows/deploy.yml`, all served from **one public IP** through a GKE Ingress.

| App | Stack | URL path | Container port |
|---|---|---|---|
| `nginx-sample` | nginx static site | `/` | 80 |
| `hello-node` | Node.js (no deps) | `/node` | 8080 |
| `hello-python` | Python stdlib (no deps) | `/python` | 8080 |

```
Applications/apps/<name>/Dockerfile   image for the app
Applications/apps/<name>/k8s/         Deployment + ClusterIP Service (namespace: apps)
Applications/k8s/namespace.yaml       "apps" namespace
Applications/k8s/ingress.yaml         path routing -> one Google HTTP load balancer
```

## Pipeline

- **Push to `main`** touching `Applications/` -> only the changed apps are built, pushed to
  `us-central1-docker.pkg.dev/test1-project-234813/docker-repotest/<app>:<commit-sha>`
  and deployed (in parallel; one failing app doesn't cancel the others).
- Changes under `Applications/k8s/` re-apply the namespace and Ingress.
- **Actions -> Deploy apps to GKE (testcluster) -> Run workflow** deploys everything.
- Runs as `gke-deployer@test1-project-234813.iam.gserviceaccount.com` (push images, deploy to GKE)
  via Workload Identity Federation. Secrets: `GCP_WIF_PROVIDER`, `GCP_DEPLOYER_SA`.

## Order of first-time setup

1. `Infraautomation/setup/bootstrap-ci.ps1` (once, as project Owner)
2. Terraform pipeline -> apply (creates `testcluster` and `docker-repotest`)
3. This pipeline -> Run workflow

## Public IP

```
gcloud container clusters get-credentials testcluster --region us-central1 --project test1-project-234813
kubectl -n apps get ingress apps
```

The Google load balancer takes ~5-10 minutes to start serving after the first deploy.

## Add another app

1. Create `Applications/apps/<new-app>/` with a `Dockerfile` and `k8s/` (copy an existing app,
   rename, keep `IMAGE_PLACEHOLDER` / `VERSION_PLACEHOLDER`).
2. Add `<new-app>: Applications/apps/<new-app>/**` to the `filters:` in `deploy.yml`
   and to the `workflow_dispatch` list.
3. Add a path for it in `Applications/k8s/ingress.yaml`.
