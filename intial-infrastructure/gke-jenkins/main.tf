module "enable-google-apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "11.2.2"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

module "create_jenkins-vpc" {
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
  name                     = "jenkins"
  regional                 = false
  region                   = var.region
  zones                    = var.zones
  network                  = module.create_jenkins-vpc.network_name
  subnetwork               = module.create_jenkins-vpc.subnets_names[0]
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
      name         = "jenkins-pool"
      min_count    = 1
      max_count    = 3
      auto_upgrade = true
    }
  ]
}

resource "google_project_iam_member" "gke" {
  project = module.enable-google-apis.project_id
  role    = "roles/storage.objectViewer"

  member = "serviceAccount:${module.create-gke.service_account}"
}

module "create_workload_identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "17.1.0"
  project_id          = module.enable-google-apis.project_id
  name                = "jenkins-wi-${module.create-gke.name}"
  namespace           = "default"
  use_existing_k8s_sa = false
}

resource "google_project_iam_member" "cluster-dev" {
  project = module.enable-google-apis.project_id
  role    = "roles/container.developer"
  member  = module.create_workload_identity.gcp_service_account_fqn
}

data "google_client_config" "default" {
}

resource "kubernetes_secret" "jenkins-secrets" {
  metadata {
    name = var.jenkins_k8s_config
  }
  data = {
    project_id          = module.enable-google-apis.project_id
    kubernetes_endpoint = "https://${module.create-gke.endpoint}"
    ca_certificate      = module.create-gke.ca_certificate
    jenkins_tf_ksa      = module.create_workload_identity.k8s_service_account_name
  }
}

resource "kubernetes_secret" "git-secrets" {
  metadata {
    name = "github-secrets"
  }
  data = {
    git_username = var.git_username
    git_repo     = var.git_repo
    git_token    = var.git_token
  }
}

resource "google_storage_bucket_iam_member" "tf-state-writer" {
  bucket = var.tf-state-bucket
  role   = "roles/storage.admin"
  member = module.create_workload_identity.gcp_service_account_fqn
}

resource "google_project_iam_member" "jenkins-project" {
  project = module.enable-google-apis.project_id
  role    = "roles/editor"

  member = module.create_workload_identity.gcp_service_account_fqn
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "3.8.6"
  timeout    = 1200

  #  values = [templatefile("${path.module}/jenkins-config/values.yaml", var.project_id)]

  depends_on = [
    kubernetes_secret.git-secrets,
  ]
}
