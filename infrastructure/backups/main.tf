# --- Object Storage Bucket for PostgreSQL Backups ---
#
# This module manages the backup bucket independently from the main
# infrastructure state. Backups should outlive the compute layer.

# Look up the Object Storage namespace
data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "postgres_backups" {
  compartment_id        = var.compartment_ocid
  name                  = "oke-postgres-backups-${var.cluster_name}"
  namespace             = data.oci_objectstorage_namespace.this.namespace
  access_type           = "NoPublicAccess"
  storage_tier          = "Standard"
  object_events_enabled = false
  versioning            = "Enabled"

  lifecycle {
    prevent_destroy = true
  }
}