#!/bin/bash
# ------------------------------------------------------------------
# Cleanup script: empties and deletes the OpenTofu INFRASTRUCTURE
# state bucket and the PostgreSQL backup bucket.
#
# NOTE: This does NOT touch the backups state bucket (hineat-tfstate-backups).
#       Backup state is persistent and managed separately via
#       "[Backups] State Destroy" workflow.
#
# This is needed because Terraform doesn't manage the bucket it
# stores state in (chicken-and-egg problem). After a full
# infrastructure teardown, the buckets and their contents remain.
#
# Prerequisites:
#   - OCI CLI installed and configured (authenticated)
#   - jq installed
#
# Usage:
#   ./scripts/cleanup-state-buckets.sh [OPTIONS]
#
# Note: The backups state bucket (hineat-tfstate-backups) is NOT cleaned up
#       by this script. Use "[Backups] State Destroy" workflow for that.
#
# Options:
#   --cluster-name NAME   Cluster name (default: hineat)
#   --region REGION       OCI region (default: us-ashburn-1)
#   --dry-run             Show what would be deleted without doing it
#   --force               Skip confirmation prompt
#   --help                Show this help message
#
# Examples:
#   ./scripts/cleanup-state-buckets.sh --dry-run
#   ./scripts/cleanup-state-buckets.sh --force
#   ./scripts/cleanup-state-buckets.sh --cluster-name mycluster --force
# ------------------------------------------------------------------

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────
CLUSTER_NAME="hineat"
REGION="${OCI_REGION:-${OCI_CLI_REGION:-us-ashburn-1}}"
DRY_RUN=false
FORCE=false

# ── Parse arguments ──────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster-name) CLUSTER_NAME="$2"; shift 2 ;;
    --region)       REGION="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --force)        FORCE=true; shift ;;
    --help)
      sed -n '/^# Usage:/,/^# ---/p' "$0" | head -n -1 | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      echo "Run with --help for usage."
      exit 1
      ;;
  esac
done

# ── Dependency checks ────────────────────────────────────────────
for cmd in jq oci; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not installed."
    exit 1
  fi
done

# ── Derived values ───────────────────────────────────────────────
STATE_BUCKET="hineat-tfstate-${CLUSTER_NAME}"
BACKUP_BUCKET="oke-postgres-backups-${CLUSTER_NAME}"
NAMESPACE=$(oci os ns get | jq -r '.data')

echo "=== State Bucket Cleanup ==="
echo "Namespace:      ${NAMESPACE}"
echo "Region:         ${REGION}"
echo "State bucket:   ${STATE_BUCKET}"
echo "Backup bucket:  ${BACKUP_BUCKET}"
echo "Dry run:        ${DRY_RUN}"
echo ""

# ── Helper: list objects in a bucket ─────────────────────────────
list_objects() {
  local bucket="$1"
  oci os object list \
    --namespace "${NAMESPACE}" \
    --bucket-name "${bucket}" \
    --fields "name" \
    | jq -r '.data[].name' 2>/dev/null || true
}

# ── Helper: count objects in a bucket ────────────────────────────
count_objects() {
  local bucket="$1"
  list_objects "$bucket" | grep -c . || echo "0"
}

# ── Helper: empty a bucket (delete all objects) ──────────────────
empty_bucket() {
  local bucket="$1"
  local count
  count=$(count_objects "$bucket")

  if [ "$count" -eq 0 ]; then
    echo "  Bucket '${bucket}' is already empty."
    return 0
  fi

  echo "  Found ${count} object(s) in '${bucket}'."

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would delete all objects from '${bucket}'."
    return 0
  fi

  echo "  Deleting all objects from '${bucket}'..."
  list_objects "$bucket" | while IFS= read -r obj; do
    [ -z "$obj" ] && continue
    echo "    Deleting: ${obj}"
    oci os object delete \
      --namespace "${NAMESPACE}" \
      --bucket-name "${bucket}" \
      --name "${obj}" \
      --force
  done
  echo "  All objects deleted from '${bucket}'."
}

# ── Helper: delete a bucket ──────────────────────────────────────
delete_bucket() {
  local bucket="$1"

  if ! oci os bucket get --namespace "${NAMESPACE}" --bucket-name "${bucket}" &>/dev/null; then
    echo "  Bucket '${bucket}' does not exist. Skipping."
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would delete bucket '${bucket}'."
    return 0
  fi

  echo "  Deleting bucket '${bucket}'..."
  oci os bucket delete \
    --namespace "${NAMESPACE}" \
    --bucket-name "${bucket}" \
    --force
  echo "  Bucket '${bucket}' deleted."
}

# ── Confirm ──────────────────────────────────────────────────────
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo "WARNING: This will permanently delete:"
  echo "  - All objects in '${STATE_BUCKET}' (including Terraform state files)"
  echo "  - The '${STATE_BUCKET}' bucket itself"
  echo "  - All objects in '${BACKUP_BUCKET}' (including PostgreSQL backups)"
  echo "  - The '${BACKUP_BUCKET}' bucket itself"
  echo ""
  read -rp "Type 'delete state buckets' to confirm: " CONFIRM
  if [ "$CONFIRM" != "delete state buckets" ]; then
    echo "Aborted."
    exit 1
  fi
  echo ""
fi

# ── Clean up state bucket ───────────────────────────────────────
echo "── State Bucket ──"
empty_bucket "${STATE_BUCKET}"
delete_bucket "${STATE_BUCKET}"
echo ""

# ── Clean up backup bucket ──────────────────────────────────────
echo "── Backup Bucket ──"
empty_bucket "${BACKUP_BUCKET}"
delete_bucket "${BACKUP_BUCKET}"
echo ""

# ── Verify ───────────────────────────────────────────────────────
echo "── Verification ──"
for bucket in "${STATE_BUCKET}" "${BACKUP_BUCKET}"; do
  if oci os bucket get --namespace "${NAMESPACE}" --bucket-name "${bucket}" &>/dev/null; then
    echo "  ${bucket} — still exists (unexpected)"
  else
    echo "  ${bucket} — gone ✓"
  fi
done

echo ""
echo "=== Cleanup Complete ==="