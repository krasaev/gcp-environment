terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.90.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.3.0"
    }
  }
}

data "google_client_config" "default" {
}

provider "kubernetes" {
  host                   = "https://${module.create-gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.create-gke.ca_certificate)
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(module.create-gke.ca_certificate)
    host                   = "https://${module.create-gke.endpoint}"
    token                  = data.google_client_config.default.access_token
  }
}
