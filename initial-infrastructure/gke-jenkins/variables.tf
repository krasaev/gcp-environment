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
  default     = "k8s-network"
}

variable "subnet_ip" {
  description = "IP range for the subnet"
  default     = "10.10.10.0/24"
}

variable "subnet_name" {
  description = "Name for the subnet"
  default     = "k8s-subnet"
}

variable "k8s_config" {
  description = "Name for the k8s secret required to configure k8s executers on Jenkins"
  default     = "k8s-config"
}

variable "jenkins_namespace" {
  description = "Name of namespace where jenkins will be deployed"
  default     = "jenkins"
}

variable "git-app-id" {
  description = "Github organization id"
}

variable "git-org-name" {
  description = "Github organization name"
}

variable "git-private-key" {
  description = "Github organization private key"
}
