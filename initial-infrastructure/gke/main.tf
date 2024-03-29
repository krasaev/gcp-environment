module "enable-google-apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "11.2.3"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage-component.googleapis.com",
    "logging.googleapis.com",
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "artifactregistry.googleapis.com",
  ]
}

module "gke-vpc" {
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

module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                  = "17.1.0"
  project_id               = module.enable-google-apis.project_id
  name                     = "env-cluster"
  regional                 = false
  region                   = var.region
  zones                    = var.zones
  network                  = module.gke-vpc.network_name
  subnetwork               = module.gke-vpc.subnets_names[0]
  ip_range_pods            = var.ip_range_pods_name
  ip_range_services        = var.ip_range_services_name
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  remove_default_node_pool = true
  service_account          = "create"
  identity_namespace       = "${module.enable-google-apis.project_id}.svc.id.goog"
  node_metadata            = "GKE_METADATA_SERVER"
  node_pools               = [
    {
      name         = "env-pool"
      machine_type = "e2-standard-2"
      min_count    = 3
      max_count    = 6
      auto_upgrade = true
    }
  ]
  depends_on               = [google_compute_ssl_certificate.env_domain_cert]
}

resource "google_project_iam_member" "gke_member" {
  project = module.enable-google-apis.project_id
  role    = "roles/storage.objectViewer"

  member = "serviceAccount:${module.gke.service_account}"
}

resource "kubernetes_secret" "gke_config" {
  metadata {
    name = var.gke_config
  }
  data = {
    kubernetes_endpoint = "https://${module.gke.endpoint}"
    ca_certificate      = module.gke.ca_certificate
  }
}

locals {
  domains      = {
    jenkins_domain = "jenkins.${var.ingress_domain}"
    grafana_domain = "grafana.${var.ingress_domain}"
    sonar_domain   = "sonar.${var.ingress_domain}"
    kibana_domain  = "kibana.${var.ingress_domain}"
    self_domain    = var.ingress_domain
  }
  domains_cert = {
    priv_key = var.ingress_domain_cert_private_key != "" ? file(var.ingress_domain_cert_private_key) : tls_private_key.domain_self_signed_private_key[0].private_key_pem
    cert     = var.ingress_domain_cert_public_key != "" ? file(var.ingress_domain_cert_public_key) : tls_self_signed_cert.domain_self_signed_cert[0].cert_pem
  }
}

resource "google_compute_ssl_certificate" "env_domain_cert" {
  name        = random_id.certificate.hex
  private_key = local.domains_cert.priv_key
  certificate = local.domains_cert.cert
  project     = module.enable-google-apis.project_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "certificate" {
  byte_length = 4
  prefix      = "env-domain-cert-"

  keepers = {
    private_key = sha256(local.domains_cert.priv_key)
    certificate = sha256(local.domains_cert.cert)
  }
}

resource "tls_private_key" "domain_self_signed_private_key" {
  count     = var.ingress_domain_cert_private_key != "" ? 0 : 1
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "domain_self_signed_cert" {
  count           = length(tls_private_key.domain_self_signed_private_key)
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.domain_self_signed_private_key[0].private_key_pem

  subject {
    common_name  = var.ingress_domain
    organization = "Self signed cert"
  }
  dns_names = values(local.domains)

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_artifact_registry_repository" "oci_image_repo" {
  provider = google-beta

  location = var.region
  repository_id = "oci-image-repo"
  description = "OCI images repository"
  format = "DOCKER"
  project = module.enable-google-apis.project_id
}

resource "google_artifact_registry_repository" "maven_repo" {
  provider = google-beta

  location = var.region
  repository_id = "maven-repo"
  description = "Maven repository"
  format = "MAVEN"
  project = module.enable-google-apis.project_id
}

resource "google_artifact_registry_repository_iam_member" "gke_image_repo_role" {
  provider = google-beta

  project = google_artifact_registry_repository.oci_image_repo.project
  location = google_artifact_registry_repository.oci_image_repo.location
  repository = google_artifact_registry_repository.oci_image_repo.name
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${module.gke.service_account}"
}

resource "google_artifact_registry_repository_iam_member" "gke_maven_repo_role" {
  provider = google-beta

  project = google_artifact_registry_repository.maven_repo.project
  location = google_artifact_registry_repository.maven_repo.location
  repository = google_artifact_registry_repository.maven_repo.name
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${module.gke.service_account}"
}