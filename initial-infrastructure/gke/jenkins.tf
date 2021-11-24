resource "kubernetes_namespace" "jenkins_namespace" {
  metadata {
    annotations = {
      name = "jenkins-namespace"
    }

    labels = {
      namespace = var.jenkins_namespace
    }
    name = var.jenkins_namespace
  }
  depends_on = [module.gke]
}

module "jenikins_identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "17.1.0"
  project_id          = module.enable-google-apis.project_id
  name                = "jenkins-wi-${module.gke.name}"
  namespace           = kubernetes_namespace.jenkins_namespace.metadata[0].name
  use_existing_k8s_sa = false
}

resource "google_storage_bucket_iam_member" "tf-state-writer" {
  bucket = var.tf-state-bucket
  role   = "roles/storage.admin"
  member = module.jenikins_identity.gcp_service_account_fqn
}

# enable GSA to add and delete pods for jenkins builders
resource "google_project_iam_member" "cluster-dev" {
  project = module.enable-google-apis.project_id
  role    = "roles/container.developer"
  member  = module.jenikins_identity.gcp_service_account_fqn
}

# Grant Jenkins SA Permissions project editor //TODO narrow scope
resource "google_project_iam_member" "jenkins-project" {
  project = module.enable-google-apis.project_id
  role    = "roles/editor"

  member = module.jenikins_identity.gcp_service_account_fqn
}

resource "kubernetes_secret" "jenkins_secrets" {
  metadata {
    name      = "jenkins-config"
    namespace = kubernetes_namespace.jenkins_namespace.metadata[0].name
  }
  data = {
    git-app-id      = var.git-app-id
    git-private-key = var.git-private-key
    git-org-name    = var.git-org-name
    project-id      = module.enable-google-apis.project_id
    jenkins-tf-ksa  = module.jenikins_identity.k8s_service_account_name
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "3.8.8"
  timeout    = 1200
  namespace  = kubernetes_secret.jenkins_secrets.metadata[0].namespace

  values = [
    file("${path.module}/jenkins-config/values.yaml"), yamlencode({
      controller : {
        ingress : {
          enabled : true
          annotations : {
            "ingress.gcp.kubernetes.io/pre-shared-cert" : google_compute_ssl_certificate.env_domain_cert.name
            "kubernetes.io/ingress.allow-http" : "true"
            "networking.gke.io/v1beta1.FrontendConfig" : "https-redirect-frontend-config"
          }
          hostName : local.domains.jenkins_domain
        }
      }
    })
  ]
  depends_on = [kubectl_manifest.jenkins_https_redirect_frontend_config]
}

resource "kubectl_manifest" "jenkins_https_redirect_frontend_config" {
  yaml_body = yamlencode({
    "apiVersion" : "networking.gke.io/v1beta1",
    "kind" : "FrontendConfig",
    "metadata" : {
      "name" : "https-redirect-frontend-config"
      "namespace" : kubernetes_namespace.jenkins_namespace.metadata[0].name
    },
    "spec" : {
      "redirectToHttps" : {
        "enabled" : true
      }
    }
  })
}