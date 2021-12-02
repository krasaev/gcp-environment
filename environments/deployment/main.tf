terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
  }
}

provider "kubernetes" {
}

provider "helm" {
}

resource "kubernetes_namespace" "awesome-ordering-system" {
  metadata {
    annotations = {
      name = "awesome-ordering-system"
    }

    labels = {
      namespace = "awesome-ordering-system"
    }
    name = "awesome-ordering-system"
  }
}

resource "helm_release" "dependencies" {

  namespace = kubernetes_namespace.awesome-ordering-system.metadata[0].name
  name       = "dependencies"
  chart      = "./awesome-ordering-system"
  dependency_update = true
}