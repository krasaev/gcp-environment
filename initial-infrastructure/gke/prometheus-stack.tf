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
  timeout    = 1200
  namespace  = kubernetes_namespace.prometheus_namespace.metadata[0].name

  values = [
    file("${path.module}/prometheus-stack-config/values.yaml"), yamlencode({
      grafana : {
        ingress : {
          enabled : true
          annotations : {
            "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
            "kubernetes.io/ingress.allow-http" : "false"
          }
          path : "/"
          hosts : [local.domains.grafana_domain]
        }
      }
    })
  ]
}