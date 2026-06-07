#!/bin/bash
# ------------------------------------------------------------------
# Bootstrap script: creates the OCI Object Storage buckets for remote state.
#
# Creates TWO buckets:
#   1. hineat-tfstate-{cluster_name}       — disposable infrastructure state
#   2. hineat-tfstate-backups              — persistent backups state
#
# Prerequisites:
#   - OCI CLI installed and configured (authenticated)
#   - jq installed
#
# Usage:
#   ./scripts/bootstrap-state.sh <compartment_ocid> [cluster_name]
#
# Example:
#   ./scripts/bootstrap-state.sh ocid1.compartment.oc1..aaaa... hineat
# ------------------------------------------------------------------

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  echo "Install it with: brew install jq  (macOS)  or  apt install jq  (Linux)"
  exit 1
fi

COMPARTMENT_OCID="${1:?Usage: $0 <compartment_ocid> [cluster_name]}"
CLUSTER_NAME="${2:-hineat}"
INFRA_BUCKET="hineat-tfstate-${CLUSTER_NAME}"
BACKUPS_BUCKET="hineat-tfstate-backups"

echo "=== Bootstrapping Remote State Backend ==="
echo "Compartment:      ${COMPARTMENT_OCID}"
echo "Infra bucket:     ${INFRA_BUCKET}"
echo "Backups bucket:   ${BACKUPS_BUCKET}"
echo ""

# Get the Object Storage namespace
NAMESPACE=$(oci os ns get | jq -r '.data')
echo "Object Storage namespace: ${NAMESPACE}"

# Helper: create a bucket if it doesn't exist
create_bucket() {
  local bucket_name="$1"
  local description="$2"

  if oci os bucket get --namespace "${NAMESPACE}" --bucket-name "${bucket_name}" &>/dev/null; then
    echo "  Bucket '${bucket_name}' already exists. Skipping."
  else
    echo "  Creating bucket '${bucket_name}'..."
    oci os bucket create \
      --compartment-id "${COMPARTMENT_OCID}" \
      --name "${bucket_name}" \
      --namespace "${NAMESPACE}" \
      --public-access-type "NoPublicAccess" \
      --storage-tier "Standard" \
      --versioning "Enabled"
    echo "  ${description} bucket created."
  fi
}

echo "── Infrastructure State Bucket ──"
create_bucket "${INFRA_BUCKET}" "Infrastructure state"

echo ""
echo "── Backups State Bucket ──"
create_bucket "${BACKUPS_BUCKET}" "Backups state"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Backups state bucket is SEPARATE from infrastructure state."
echo "This means backup state persists even if infrastructure is destroyed."