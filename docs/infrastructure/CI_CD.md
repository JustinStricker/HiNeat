# CI/CD Pipelines — Infrastructure

19 GitHub Actions workflows organized by layer.

## Infrastructure Layer (OCI Cloud Resources)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Infra Apply** | workflow_dispatch | Validate, plan, apply Terraform changes (VCN, OKE, IAM, networking) |
| **Infra Destroy** | workflow_dispatch | Tear down OCI resources (preserves backup bucket) |
| **Infra State Refresh** | workflow_dispatch | Sync Terraform state with actual OCI resources |
| **Infra Drift Check** | workflow_dispatch | Detect differences between state and reality |
| **Infra Bootstrap State** | workflow_dispatch | Create OCI Object Storage bucket for remote state |

## Backups Layer

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Backups Drift Check** | workflow_dispatch | Detect drift in backup bucket state |
| **Backups Destroy** | workflow_dispatch | Tear down backup bucket |
| **Backups State Apply** | workflow_dispatch | Apply backup state changes |
| **Backups State Destroy** | workflow_dispatch | Destroy backup state |

## PostgreSQL Layer

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Postgres Deploy** | workflow_dispatch | Install CSI driver, cert-manager, CNPG operator, deploy PostgreSQL |
| **Postgres Destroy** | workflow_dispatch | Tear down PostgreSQL cluster, CNPG operator, cert-manager |
| **Postgres Backups** | workflow_dispatch | Create/update Barman Cloud ObjectStore and credentials |

## App Layer

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **App CI** | workflow_dispatch | Build, test, deploy server: Docker → OCIR → OKE |
| **App Destroy** | workflow_dispatch | Delete K8s resources + Cloudflare DNS record |

## Web Layer

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Web Deploy** | push to main (web-relevant paths) | Build Wasm/JS client → Cloudflare Pages |
| **Web Destroy** | workflow_dispatch | Remove Pages project + DNS CNAME |

## Required GitHub Secrets

| Secret | Used By |
|--------|---------|
| `OCI_USER_OCID` | All infra workflows |
| `OCI_TENANCY_OCID` | All infra workflows |
| `OCI_FINGERPRINT` | All infra workflows |
| `OCI_PRIVATE_KEY` | All infra workflows |
| `OCI_REGION` | All infra workflows |
| `OCI_COMPARTMENT_OCID` | All infra workflows |
| `OCI_AUTH_TOKEN` | App CI (OCIR Docker login) |
| `OCIR_USER_NAME` | App CI (OCIR Docker login) |
| `CLOUDFLARE_API_TOKEN` | Web deploy |
| `CLOUDFLARE_ACCOUNT_ID` | Web deploy |
