output "cluster_id" {
  description = "The OCID of the OKE cluster."
  value       = oci_containerengine_cluster.this.id
}

output "cluster_name" {
  description = "Name of the OKE cluster."
  value       = oci_containerengine_cluster.this.name
}

output "kubernetes_version" {
  description = "Kubernetes version running on the cluster."
  value       = oci_containerengine_cluster.this.kubernetes_version
}

output "node_pool_id" {
  description = "The OCID of the node pool."
  value       = oci_containerengine_node_pool.this.id
}

output "node_pool_size" {
  description = "Number of worker nodes."
  value       = var.node_pool_size
}

output "vcn_id" {
  description = "The OCID of the VCN."
  value       = oci_core_vcn.this.id
}

output "node_subnet_id" {
  description = "The OCID of the worker node subnet."
  value       = oci_core_subnet.node.id
}

output "compartment_id" {
  description = "The OCID of the compartment."
  value       = var.compartment_ocid
}

output "kubeconfig_command" {
  description = "Command to generate kubeconfig for this cluster."
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.this.id} --file $$HOME/.kube/config --region ${var.region} --token-version 2.0.0"
}
