output "backup_bucket_name" {
  description = "Name of the OCI Object Storage bucket for PostgreSQL backups."
  value       = oci_objectstorage_bucket.postgres_backups.name
}

output "backup_bucket_namespace" {
  description = "Object Storage namespace for the backup bucket."
  value       = data.oci_objectstorage_namespace.this.namespace
}