# Primary entrypoint for the infrastructure root module.
#
# Resources are split across descriptive files for navigation:
#   networking.tf  — VCN, subnets, security lists, gateways
#   oke.tf         — OKE cluster, node pool
#   iam.tf         — Dynamic group, OCIR policy
#   backups/       — Separate root module for backup bucket state