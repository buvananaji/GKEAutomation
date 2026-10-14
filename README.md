# GKEAutomation

Create a GKE test environment, deploy the apps, test them, and delete everything afterwards,
all from GitHub Actions.

```
Infraautomation/terraform/   testcluster (GKE) + docker-repotest (Artifact Registry)
Infraautomation/setup/       one-time Google Cloud setup (service accounts, keyless GitHub sign-in)
Applications/apps/           nginx-sample (/), hello-node (/node), hello-python (/python)
Applications/k8s/            "apps" namespace + one Ingress (one public IP for all apps)
.github/workflows/           pipelines (below)
```

## Test environment lifecycle: `environment.yml`

**Actions → Test environment (testcluster) → Run workflow.** It only ever runs when started by hand.

| action | What happens |
|---|---|
| `create` | Terraform plan → **approve** (`production`) → apply → build & deploy all apps → smoke test (`/`, `/node`, `/python`) → URLs in the run summary |
| `destroy` (type `testcluster` in *confirm*) | **approve** → delete Ingress/load balancer and apps → Terraform destroy of node pool, cluster and registry |

Typical cycle:

1. Run `create` and approve. About 15–20 min later the summary shows the test URLs.
2. Test.
3. Run `destroy` with confirm `testcluster` and approve. After this, nothing is left billing except the items listed under *Kept* below.

`create` on an environment that already exists skips the infra step and just redeploys the apps.

**Kept by `destroy`:** enabled APIs, the Terraform state bucket, service accounts and, if reserved,
the static Ingress IP. Keeping the IP means the next `create` gets the same URL. An unused reserved IP
costs about $0.01/hour.

## Day-to-day pipelines

| Workflow | Runs when | Does |
|---|---|---|
| `terraform.yml` | PR / push touching `Infraautomation/terraform/` | plan (PR comment) → approve → apply |
| `deploy.yml` | push touching `Applications/`, or manually | build & deploy only the changed apps |

`terraform.yml` and `environment.yml` share a lock, so they never change the infrastructure at the same time.
While the environment is destroyed, `deploy.yml` runs fail (no cluster). Run `create` first.

## One-time setup

`Infraautomation/setup/bootstrap-ci.sh`, run in Google Cloud Shell as project Owner. It is already done for
`test1-project-234813`.
