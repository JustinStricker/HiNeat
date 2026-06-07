# --- Remote State Backend Configuration ---
#
# This backend uses a SEPARATE bucket from the main infrastructure state.
# Backups should outlive the compute layer — if infrastructure state is
# destroyed, backup state and the backup bucket persist.
#
# Prerequisites:
#   1. Run the "[Backups] State Apply" GitHub Actions workflow
#      (Creates the bucket "hineat-tfstate-backups" in your compartment)
#   2. Run: OCI_NAMESPACE=$(oci os ns get | jq -r '.data') && \
#           OCI_REGION=us-ashburn-1 && \
#           tofu init \
#             -backend-config="region=${OCI_REGION}" \
#             -backend-config="endpoint=https://${OCI_NAMESPACE}.compat.objectstorage.${OCI_REGION}.oraclecloud.com"
#   3. Run: tofu init -migrate-state
#

terraform {
  backend "s3" {
    bucket                      = "hineat-tfstate-backups"
    key                         = "infrastructure/backups/terraform.tfstate"
    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}