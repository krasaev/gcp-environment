terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.90.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.1"
    }
  }
}

data "google_client_config" "default" {
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "kubectl" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
  }
}
