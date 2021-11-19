#FIXME fix certification
#resource "kubernetes_namespace" "efk_namespace" {
#  metadata {
#    annotations = {
#      name = "efk-namespace"
#    }
#
#    labels = {
#      namespace = var.efk_namespace
#    }
#    name = var.efk_namespace
#  }
#  depends_on = [module.gke]
#}
#
#resource "helm_release" "elasticsearch" {
#  name       = "efk-elasticsearch"
#  repository = "https://helm.elastic.co"
#  chart      = "elasticsearch"
#  version    = "7.15.0"
#  timeout    = 1200
#  namespace  = kubernetes_namespace.efk_namespace.metadata[0].name
#  values     = [file("${path.module}/efk-stack-config/elastic-values.yaml")]
#  depends_on = [kubernetes_secret.elastic_certificates_p12, kubernetes_secret.elastic_credentials]
#}
#
#resource "helm_release" "fluentd" {
#  name       = "efk-fluentd"
#  repository = "https://fluent.github.io/helm-charts"
#  chart      = "fluentd"
#  version    = "0.3.0"
#  timeout    = 1200
#  namespace  = helm_release.elasticsearch.namespace
#  values     = [file("${path.module}/efk-stack-config/fluentd-values.yaml")]
#}
#
#resource "helm_release" "kibana" {
#  name       = "efk-kibana"
#  repository = "https://helm.elastic.co"
#  chart      = "kibana"
#  version    = "7.15.0"
#  timeout    = 1200
#  namespace  = helm_release.elasticsearch.namespace
#
#  values = [
#    file("${path.module}/efk-stack-config/kibana-values.yaml"), yamlencode({
#      ingress : {
#        enabled : true
#        annotations : {
#          "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
#          "kubernetes.io/ingress.allow-http" : "false"
#        }
#        hosts : [
#          {
#            host : local.domains.kibana_domain
#            paths : [{ path : "/" }]
#          }
#        ]
#      }
#    })
#  ]
#  depends_on = [helm_release.elasticsearch]
#}
#
#resource "kubernetes_secret" "elastic_certificates_p12" {
#  metadata {
#    namespace = kubernetes_namespace.efk_namespace.metadata[0].name
#    name      = "elastic-certificates"
#  }
#
#  binary_data = {
#    "elastic-certificates.p12" = pkcs12_from_pem.elasticsearch_pkcs12.result
#  }
#
#  type = "Opaque"
#}
#
#resource "kubernetes_secret" "elastic_certificate_pem" {
#  metadata {
#    namespace = kubernetes_namespace.efk_namespace.metadata[0].name
#    name      = "elastic-certificate-pem"
#  }
#
#  data = {
#    "elastic-certificate.pem" = tls_self_signed_cert.elasticsearch_cert.cert_pem
#  }
#
#  type = "Opaque"
#}
#
#resource "kubernetes_secret" "elastic_credentials" {
#  metadata {
#    namespace = kubernetes_namespace.efk_namespace.metadata[0].name
#    name      = "elastic-credentials"
#  }
#
#  data = {
#    username = "elastic"
#    password = random_password.elastic_password.result
#  }
#
#  type = "Opaque"
#}
#
#resource "random_password" "elastic_password" {
#  length           = 16
#  special          = true
#  override_special = "_%@"
#}
#
#resource "random_password" "kibana_encryption_key" {
#  length  = 32
#  special = true
#}
#
#resource "kubernetes_secret" "kibana_encryption_secret" {
#  metadata {
#    namespace = kubernetes_namespace.efk_namespace.metadata[0].name
#    name      = "kibana-encryption-key"
#  }
#
#  data = {
#    encryptionkey = random_password.kibana_encryption_key.result
#  }
#
#  type = "Opaque"
#}
#
## TODO extract to separate module
#resource "tls_private_key" "elasticsearch_priv_key" {
#  algorithm = "RSA"
#}
#
#resource "tls_self_signed_cert" "elasticsearch_cert" {
#  key_algorithm   = "RSA"
#  private_key_pem = tls_private_key.elasticsearch_priv_key.private_key_pem
#
#  subject {
#    common_name  = "elasticsearch"
#    organization = "Self signed cert"
#  }
#
#  validity_period_hours = 2562047
#
#  is_ca_certificate = true
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "server_auth",
#    "cert_signing",
#  ]
#}
#
#resource "pkcs12_from_pem" "elasticsearch_pkcs12" {
#  password        = ""
#  cert_pem        = tls_self_signed_cert.elasticsearch_cert.cert_pem
#  private_key_pem = tls_private_key.elasticsearch_priv_key.private_key_pem
#}