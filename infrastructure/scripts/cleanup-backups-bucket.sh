#!/bin/bash
# ------------------------------------------------------------------
# Cleanup script: empties and deletes the PostgreSQL backup bucket.
#
# The backup bucket is managed by Terraform (infrastructure/backups/)
# but Terraform cannot empty a bucket before deleting it. This script
# handles the emptying step so that `tofu destroy` or direct OCI CLI
# deletion can succeed.
#
# Prerequisites:
#   - OCI CLI installed and configured (authenticated)
#   - jq installed
#
# Usage:
#   ./scripts/cleanup-backups-bucket.sh [OPTIONS]
#
# Options:
#   --cluster-name NAME   Cluster name (default: hineat)
#   --dry-run             Show what would be deleted without doing it
#   --force               Skip confirmation prompt
#   --help                Show this help message
#
# Examples:
#   ./scripts/cleanup-backups-bucket.sh --dry-run
#   ./scripts/cleanup-backups-bucket.sh --force
#   ./scripts/cleanup-backups-bucket.sh --cluster-name mycluster --force
# ------------------------------------------------------------------

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────
CLUSTER_NAME="hineat"
DRY_RUN=false
FORCE=false

# ── Parse arguments ──────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster-name) CLUSTER_NAME="$2"; shift 2 ;;
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
BUCKET_NAME="oke-postgres-backups-${CLUSTER_NAME}"
NAMESPACE=$(oci os ns get | jq -r '.data')

echo "=== Backup Bucket Cleanup ==="
echo "Namespace:  ${NAMESPACE}"
echo "Bucket:     ${BUCKET_NAME}"
echo "Dry run:    ${DRY_RUN}"
echo ""

# ── Check if bucket exists ───────────────────────────────────────
if ! oci os bucket get --namespace "${NAMESPACE}" --bucket-name "${BUCKET_NAME}" &>/dev/null; then
  echo "Bucket '${BUCKET_NAME}' does not exist. Nothing to clean up."
  exit 0
fi

# ── List and count objects ───────────────────────────────────────
list_objects() {
  oci os object list \
    --namespace "${NAMESPACE}" \
    --bucket-name "${BUCKET_NAME}" \
    --fields "name" \
    | jq -r '.data[].name' 2>/dev/null || true
}

OBJECT_COUNT=$(list_objects | grep -c . || echo "0")

echo "Found ${OBJECT_COUNT} object(s) in '${BUCKET_NAME}':"
if [ "$OBJECT_COUNT" -gt 0 ]; then
  list_objects | while IFS= read -r obj; do
    [ -z "$obj" ] && continue
    echo "  - ${obj}"
  done
fi
echo ""

# ── Confirm ──────────────────────────────────────────────────────
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo "WARNING: This will permanently delete:"
  echo "  - All ${OBJECT_COUNT} object(s) in '${BUCKET_NAME}' (including PostgreSQL backups)"
  echo "  - The '${BUCKET_NAME}' bucket itself"
  echo ""
  read -rp "Type 'delete backup bucket' to confirm: " CONFIRM
  if [ "$CONFIRM" != "delete backup bucket" ]; then
    echo "Aborted."
    exit 1
  fi
  echo ""
fi

# ── Empty the bucket ─────────────────────────────────────────────
if [ "$OBJECT_COUNT" -gt 0 ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would delete all ${OBJECT_COUNT} object(s) from '${BUCKET_NAME}'."
  else
    echo "Deleting all objects from '${BUCKET_NAME}'..."
    list_objects | while IFS= read -r obj; do
      [ -z "$obj" ] && continue
      echo "  Deleting: ${obj}"
      oci os object delete \
        --namespace "${NAMESPACE}" \
        --bucket-name "${BUCKET_NAME}" \
        --name "${obj}" \
        --force
    done
    echo "All objects deleted."
  fi
else
  echo "Bucket is already empty."
fi
echo ""

# ── Delete the bucket ────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would delete bucket '${BUCKET_NAME}'."
else
  echo "Deleting bucket '${BUCKET_NAME}'..."
  oci os bucket delete \
    --namespace "${NAMESPACE}" \
    --bucket-name "${BUCKET_NAME}" \
    --force
  echo "Bucket '${BUCKET_NAME}' deleted."
fi
echo ""

# ── Verify ───────────────────────────────────────────────────────
echo "── Verification ──"
if oci os bucket get --namespace "${NAMESPACE}" --bucket-name "${BUCKET_NAME}" &>/dev/null; then
  echo "  ${BUCKET_NAME} — still exists (unexpected)"
else
  echo "  ${BUCKET_NAME} — gone ✓"
fi

echo ""
echo "=== Backup Bucket Cleanup Complete ==="