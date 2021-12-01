resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    annotations = {
      name = "prometheus-namespace"
    }

    labels = {
      namespace = var.prometheus_namespace
    }
    name = var.prometheus_namespace
  }
  depends_on = [module.gke]
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "19.2.3"
  timeout    = 500
  namespace  = kubernetes_namespace.prometheus_namespace.metadata[0].name

  values = [
    file("${path.module}/prometheus-stack-config/values.yaml"), yamlencode({
      grafana : {
        adminPassword : random_password.grafana_password.result
        ingress : {
          enabled : true
          annotations : {
            "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
            "kubernetes.io/ingress.allow-http" : "true"
            "networking.gke.io/v1beta1.FrontendConfig" : "https-redirect-frontend-config"
          }
          path : "/"
          hosts : [local.domains.grafana_domain]
        }
      }
    })
  ]
  depends_on = [kubectl_manifest.grafana_https_redirect_frontend_config]
}

resource "kubectl_manifest" "grafana_https_redirect_frontend_config" {
  yaml_body = yamlencode({
    "apiVersion" : "networking.gke.io/v1beta1",
    "kind" : "FrontendConfig",
    "metadata" : {
      "name" : "https-redirect-frontend-config"
      "namespace" : kubernetes_namespace.prometheus_namespace.metadata[0].name
    },
    "spec" : {
      "redirectToHttps" : {
        "enabled" : true
      }
    }
  })
}

resource "random_password" "grafana_password" {
  length  = 24
  special = true
}