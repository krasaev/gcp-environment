
resource "kubernetes_namespace" "elastic_system" {
  metadata {
    annotations = {
      name = "elastic-system"
    }

    labels = {
      namespace = "elastic-system"
    }
    name = "elastic-system"
  }
}

resource "kubernetes_namespace" "efk" {
  metadata {
    annotations = {
      name = "efk-namespace"
    }

    labels = {
      namespace = var.efk_namespace
    }
    name = var.efk_namespace
  }
}

resource "helm_release" "eck_operator_crds" {
  name       = "elastic-operator-crds"
  repository = "https://helm.elastic.co"
  chart      = "eck-operator-crds"
  version    = "1.8.0"
  timeout    = 1200
}

resource "helm_release" "eck_operator" {
  name       = "elastic-operator"
  repository = "https://helm.elastic.co"
  chart      = "eck-operator"
  version    = "1.8.0"
  timeout    = 1200
  namespace  = kubernetes_namespace.elastic_system.metadata[0].name
  values     = [file("${path.module}/efk-stack-config/profile-restricted.yaml")]

  set {
    name  = "managedNamespaces"
    value = "{\"${kubernetes_namespace.efk.metadata[0].name}\"}"
  }
  depends_on = [helm_release.eck_operator_crds]
}

data "kubectl_path_documents" "efk_definitions" {
  pattern = "${path.module}/efk-stack-config/efk-*.yaml"
  vars = {
    namespace     = var.efk_namespace
    kibana_domain = local.domains.kibana_domain
    elastic_version = "7.15.2"
  }
}

resource "kubectl_manifest" "efk" {
  for_each  = toset(data.kubectl_path_documents.efk_definitions.documents)
  yaml_body = each.value

  depends_on = [helm_release.eck_operator]
}

resource "kubectl_manifest" "kibana_ingress" {
  yaml_body = yamlencode({
    "apiVersion" : "networking.k8s.io/v1",
    "kind" : "Ingress",
    "metadata" : {
      "name" : "kibana-ingress",
      "namespace" : kubernetes_namespace.efk.metadata[0].name,
      "annotations" : {
        "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
        "kubernetes.io/ingress.allow-http" : "true"
        "networking.gke.io/v1beta1.FrontendConfig" : "https-redirect-frontend-config"
      }
    },
    "spec" : {
      "rules" : [
        {
          "host" : local.domains.kibana_domain,
          "http" : {
            "paths" : [
              {
                "path" : "/",
                "pathType" : "Prefix"
                "backend" : {
                  "service" : {
                    name : "kibana-kb-http"
                    port : {
                      number : 5601
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
  depends_on = [kubectl_manifest.efk, kubectl_manifest.kibana_https_redirect_frontend_config]
}

resource "kubectl_manifest" "kibana_https_redirect_frontend_config" {
  yaml_body = yamlencode({
    "apiVersion" : "networking.gke.io/v1beta1",
    "kind" : "FrontendConfig",
    "metadata" : {
      "name" : "https-redirect-frontend-config"
      "namespace" : kubernetes_namespace.efk.metadata[0].name
    },
    "spec" : {
      "redirectToHttps" : {
        "enabled" : true
      }
    }
  })
}