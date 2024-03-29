resource "kubernetes_namespace" "sonar_namespace" {
  metadata {
    annotations = {
      name = "sonar-namespace"
    }

    labels = {
      namespace = var.sonar_namespace
    }
    name = var.sonar_namespace
  }
  depends_on = [module.gke]
}

resource "helm_release" "sonar" {
  name       = "sonarqube"
  repository = "https://sonarsource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  version    = "1.2.0"
  timeout    = 500
  namespace  = kubernetes_namespace.sonar_namespace.metadata[0].name

  values = [
    file("${path.module}/sonarqube-config/values.yaml"), yamlencode({
      ingress : {
        enabled : true
        annotations : {
          "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
          "kubernetes.io/ingress.allow-http" : "true"
          "networking.gke.io/v1beta1.FrontendConfig" : "https-redirect-frontend-config"
        }
        hosts : [
          {
            name : local.domains.sonar_domain
            path : "/*"
          }
        ]
      }
    })
  ]
  depends_on = [kubectl_manifest.sonar_https_redirect_frontend_config]
}

resource "kubectl_manifest" "sonar_https_redirect_frontend_config" {
  yaml_body = yamlencode({
    "apiVersion" : "networking.gke.io/v1beta1",
    "kind" : "FrontendConfig",
    "metadata" : {
      "name" : "https-redirect-frontend-config"
      "namespace" : kubernetes_namespace.sonar_namespace.metadata[0].name
    },
    "spec" : {
      "redirectToHttps" : {
        "enabled" : true
      }
    }
  })
}