output "kubernetes_endpoint" {
  description = "The cluster endpoint"
  sensitive   = true
  value       = module.create-gke.endpoint
}

output "client_token" {
  description = "The bearer token for auth"
  sensitive   = true
  value       = base64encode(data.google_client_config.default.access_token)
}

output "ca_certificate" {
  description = "The cluster ca certificate (base64 encoded)"
  value       = module.create-gke.ca_certificate
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
  value       = module.create_workload_identity.k8s_service_account_name
}

output "gcp_service_account_email" {
  description = "Email address of GCP service account."
  value       = module.create_workload_identity.gcp_service_account_email
}

output "jenkins_k8s_config_secrets" {
  description = "Name of the secret required to configure k8s executers on Jenkins"
  value       = var.jenkins_k8s_config
}

output "jenkins_project_id" {
  description = "Project id of Jenkins GKE project"
  value       = module.enable-google-apis.project_id
}

output "zone" {
  description = "Zone of Jenkins GKE cluster"
  value       = join(",", var.zones)
}