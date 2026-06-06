# Remote state stored in the same OCI Object Storage bucket as the
# main infrastructure state, but under a different key for isolation.
#
# After creating this state backend, run:
#   tofu -chdir=infrastructure/backups init \
#     -backend-config="region=${OCI_REGION}" \
#     -backend-config="endpoint=https://${OCI_NAMESPACE}.compat.objectstorage.${OCI_REGION}.oraclecloud.com"

terraform {
  backend "s3" {
    bucket                      = "oke-tfstate-oke-infrastructure"
    key                         = "infrastructure/backups/terraform.tfstate"
    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}