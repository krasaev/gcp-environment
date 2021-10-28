variable "project_id" {
  description = "The project id to deploy Jenkins on GKE"
}

variable "region" {
  description = "The GCP region to deploy instances into"
  default     = "europe-north1"
}

variable "tf-state-bucket" {
  description = "The terraform state bucket name"
}

# TODO revise
variable "zones" {
  description = "The GCP zone to deploy gke into"
  default     = ["europe-north1-a"]
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-scv"
}

variable "network_name" {
  description = "Name for the VPC network"
  default     = "jenkins-network"
}

variable "subnet_ip" {
  description = "IP range for the subnet"
  default     = "10.10.10.0/24"
}

variable "subnet_name" {
  description = "Name for the subnet"
  default     = "jenkins-subnet"
}

variable "jenkins_k8s_config" {
  description = "Name for the k8s secret required to configure k8s executers on Jenkins"
  default     = "jenkins-k8s-config"
}

variable "git_username" {
  description = "Github user/organization name where the terraform repo resides."
}

variable "git_token" {
  description = "Github token to access repo."
}

variable "git_repo" {
  description = "Github repo name."
  default     = "gcp-env"
}
