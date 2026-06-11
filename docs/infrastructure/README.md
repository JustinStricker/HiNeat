# OKE Infrastructure

Oracle Kubernetes Engine (OKE) cluster on OCI provisioned with OpenTofu, with PostgreSQL via CloudNativePG operator.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    VCN (10.0.0.0/16)                       │
│  ┌──────────────┐  ┌────────────┐  ┌───────────────────┐ │
│  │ API Endpoint  │  │   Nodes    │  │   Service LB      │ │
│  │ 10.0.0.0/28  │  │10.0.10.0/24│  │  10.0.20.0/24    │ │
│  │              │  │  ┌──────┐  │  │                   │ │
│  │              │  │  │ CNPG │  │  │                   │ │
│  │              │  │  │ PG   │  │  │                   │ │
│  │              │  │  └──────┘  │  │                   │ │
│  └──────────────┘  └────────────┘  └───────────────────┘ │
│  PostgreSQL pods get IPs from node subnet's pod CIDR      │
│  via OCI VCN IP Native CNI.                               │
│  Outbound backup traffic routes through the IGW.          │
└──────────────────────────────────────────────────────────┘
```

## Resources

| Layer | Details |
|-------|---------|
| **Networking** | VCN (10.0.0.0/16), Internet Gateway, Service Gateway, 3 subnets, 2 security lists, route table |
| **OKE Cluster** | Basic cluster, OCI VCN IP Native CNI, public API endpoint |
| **Node Pool** | 4× VM.Standard.A1.Flex (ARM Ampere, 1 OCPU, 6GB RAM each) |
| **IAM** | Dynamic group for worker nodes + policy for OCIR image pull |
| **Backups** | OCI Object Storage bucket (versioned, `prevent_destroy`) |
| **Remote State** | S3-compatible OCI Object Storage |
| **PostgreSQL** | CloudNativePG operator, 1 instance, 10Gi, Barman Cloud WAL archiving |

All resources are OCI Always Free Tier eligible.

## File Structure

```
infrastructure/
├── providers.tf           # OCI provider config
├── variables.tf           # Input variables
├── backend.tf             # Remote state (S3-compatible)
├── networking.tf          # VCN, subnets, security lists
├── oke.tf                 # OKE cluster + node pool
├── iam.tf                 # Dynamic group + OCIR policy
├── main.tf                # Main orchestration
├── outputs.tf             # Terraform outputs
├── Makefile               # Dev commands (tofu wrappers)
│
├── backups/               # Separate root module
│   ├── main.tf            # Backup bucket
│   ├── providers.tf
│   └── backend.tf
│
├── k8s/
│   ├── app/
│   │   ├── deployment.yaml   # Server Deployment + PVC
│   │   └── service.yaml      # LoadBalancer
│   └── postgres/
│       ├── cluster.yaml      # CNPG Cluster CRD
│       └── install-operator.sh
│
└── scripts/               # Shell scripts for deploy/cleanup
```

## Quick Start

```sh
# Deploy infrastructure
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu apply

# Configure kubectl
oci ce cluster create-kubeconfig \
  --cluster-id $(tofu output -raw cluster_id) \
  --file $HOME/.kube/config \
  --region us-ashburn-1 \
  --token-version 2.0.0

# Install PostgreSQL
./k8s/postgres/install-operator.sh
./scripts/reset-postgres.sh
```

## Development Workflow

```sh
make plan              # Preview changes
make apply             # Apply changes
make postgres-deploy   # Full PostgreSQL deploy
make postgres-reset    # Quick PostgreSQL recreate
make destroy           # Tear down OKE cluster + VCN
```

## CI/CD

19 GitHub Actions workflows covering infrastructure, PostgreSQL, backups, app, and web deployment. See [CI_CD.md](CI_CD.md) for details.

## Security

See [SECURITY.md](SECURITY.md) for the full security audit.
