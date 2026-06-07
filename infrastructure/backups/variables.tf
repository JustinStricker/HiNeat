variable "compartment_ocid" {
  description = "The OCID of the compartment where the backup bucket will be created."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name used to derive the backup bucket name."
  type        = string
  default     = "hineat"
}