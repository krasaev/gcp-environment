module "enable-google-apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "11.2.2"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

module "create_k8s-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "3.5.0"

  project_id   = module.enable-google-apis.project_id
  network_name = var.network_name

  subnets = [
    {
      subnet_name   = var.subnet_name
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "create-gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster/"
  version                  = "17.1.0"
  project_id               = module.enable-google-apis.project_id
  name                     = "env-cluster"
  regional                 = false
  region                   = var.region
  zones                    = var.zones
  network                  = module.create_k8s-vpc.network_name
  subnetwork               = module.create_k8s-vpc.subnets_names[0]
  ip_range_pods            = var.ip_range_pods_name
  ip_range_services        = var.ip_range_services_name
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  remove_default_node_pool = true
  service_account          = "create"
  identity_namespace       = "${module.enable-google-apis.project_id}.svc.id.goog"
  node_metadata            = "GKE_METADATA_SERVER"
  node_pools = [
    {
      name         = "env-pool"
      min_count    = 3
      max_count    = 6
      auto_upgrade = true
    }
  ]
}

resource "google_project_iam_member" "gke" {
  project = module.enable-google-apis.project_id
  role    = "roles/storage.objectViewer"

  member = "serviceAccount:${module.create-gke.service_account}"
}

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
}

module "create_jenikins_identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "17.1.0"
  project_id          = module.enable-google-apis.project_id
  name                = "jenkins-wi-${module.create-gke.name}"
  namespace           = var.jenkins_namespace
  use_existing_k8s_sa = false
}

resource "google_project_iam_member" "cluster-dev" {
  project = module.enable-google-apis.project_id
  role    = "roles/container.developer"
  member  = module.create_jenikins_identity.gcp_service_account_fqn
}

resource "kubernetes_secret" "k8s_config" {
  metadata {
    name = var.k8s_config
  }
  data = {
    kubernetes_endpoint = "https://${module.create-gke.endpoint}"
    ca_certificate      = module.create-gke.ca_certificate
  }
}

resource "kubernetes_secret" "jenkins-secrets" {
  metadata {
    name      = "jenkins-config"
    namespace = var.jenkins_namespace
  }
  data = {
    git-app-id      = var.git-app-id
    git-private-key = var.git-private-key
    git-org-name    = var.git-org-name
    project-id      = module.enable-google-apis.project_id
    jenkins-tf-ksa  = module.create_jenikins_identity.k8s_service_account_name
  }
}

resource "google_storage_bucket_iam_member" "tf-state-writer" {
  bucket = var.tf-state-bucket
  role   = "roles/storage.admin"
  member = module.create_jenikins_identity.gcp_service_account_fqn
}

resource "google_project_iam_member" "jenkins-project" {
  project = module.enable-google-apis.project_id
  role    = "roles/editor"

  member = module.create_jenikins_identity.gcp_service_account_fqn
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "3.8.6"
  timeout    = 1200
  namespace  = var.jenkins_namespace

  values = [file("${path.module}/jenkins-config/values.yaml")]

  depends_on = [
    kubernetes_secret.jenkins-secrets,
  ]
}
