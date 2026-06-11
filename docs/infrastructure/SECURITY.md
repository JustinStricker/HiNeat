# Infrastructure Security

> Audit date: 2026-05-27

## Credential Hygiene

**No hardcoded API keys, passwords, tokens, or private keys** exist in the codebase. All secrets are handled through proper channels:

- **OCI provider**: No embedded credentials — relies on env vars or instance principal
- **Terraform variables**: Sensitive variables have no defaults, supplied at runtime
- **`.gitignore`**: Ignores `*.tfvars`, `*.pem`, `*.tfstate`, `.terraform/`
- **GitHub Actions**: All secrets via `${{ secrets.* }}` exclusively
- **Git history**: No secrets ever committed (all branches inspected)

## Known Concerns

### 1. SSH Access Open to Internet

**File:** `networking.tf` — Inbound SSH (port 22) from `0.0.0.0/0`

Any IP can attempt SSH to worker nodes. OKE-managed nodes use SSH keys, but this broad access increases attack surface.

**Fix:** Restrict source CIDR to organization IP range or remove the rule.

### 2. Public Kubernetes API Endpoint

**File:** `oke.tf` — `is_public_ip_enabled = true`

Cluster's K8s API server is exposed to the public internet.

**Fix:** Set `is_public_ip_enabled = false`, access via bastion/VPN.

### 3. Static Backup Credentials in Cluster

**File:** `scripts/setup-backup.sh`

AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY persisted as a K8s Secret. Any pod with Secrets API access can read them.

**Fix:** Migrate to OCI Instance Principal authentication — worker nodes in the dynamic group can authenticate to Object Storage without static keys.

## Secret Flow

```
GitHub Actions (secrets.*)
        │
        ▼
  ┌──────────────────────┐
  │  OCI Provider         │  ← OCI_USER_OCID, OCI_TENANCY_OCID,
  │  (OpenTofu)           │     OCI_FINGERPRINT, OCI_PRIVATE_KEY
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │  OKE Cluster          │  ← compartment_ocid, tenancy_ocid
  │  + Node Pool          │     (TF_VAR_* env vars)
  └──────────┬───────────┘
             │
             ▼
  ┌──────────────────────┐
  │  CNPG Backups         │  ← AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  │  (K8s Secret)         │     *(concern #3)*
  └──────────────────────┘
```

## Scope

Audited: all `.tf` files, `.gitignore`, `terraform.tfvars.example`, all `.github/workflows/*.yml`, all `scripts/*.sh`, `k8s/postgres/*`, `Makefile`, full git history.
