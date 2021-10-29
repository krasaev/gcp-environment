output "kubernetes_endpoint" {
  description = "The cluster endpoint"
  sensitive   = true
  value       = module.create-gke.endpoint
}

output "ca_certificate" {
  description = "The cluster ca certificate (base64 encoded)"
  value       = module.create-gke.ca_certificate
  sensitive   = true
}

output "service_account" {
  description = "The default service account used for running nodes."
  value       = module.create-gke.service_account
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.create-gke.name
}

output "k8s_service_account_name" {
  description = "Name of k8s service account."
  value       = module.create_jenikins_identity.k8s_service_account_name
}

output "gcp_service_account_email" {
  description = "Email address of GCP service account."
  value       = module.create_jenikins_identity.gcp_service_account_email
}

output "k8s_config_secrets" {
  description = "Name of the secret required to configure k8s executers on Jenkins"
  value       = var.k8s_config
  sensitive   = true
}

output "project_id" {
  description = "Project id of GKE project"
  value       = module.enable-google-apis.project_id
}

output "zone" {
  description = "Zone of GKE cluster"
  value       = join(",", var.zones)
}