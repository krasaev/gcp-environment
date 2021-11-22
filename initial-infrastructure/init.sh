#!/bin/bash

CONFIG_FILE=$1
PROJECT_ID=$(gcloud config get-value project)
STATE_BUCKET_NAME=${PROJECT_ID}-tfstate

if [ ! -f "$CONFIG_FILE" ]; then
  echo "--- Configuration file was not provided"
  exit 1
fi

declare -A config

while IFS='=' read -d $'\n' -r k v; do
  if [[ $k =~ ^[A-Za-z] ]]; then
    config["$k"]="$v"
  fi
done <$CONFIG_FILE

if [[ -z "${config['domain.name']}" ]]; then
  echo "--- Required 'domain.name' property is not found"
  exit 1
fi

if [[ -z "${config['github.organization.name']}" ]]; then
  echo "--- Required 'github.organization.name' property is not found"
  exit 1
fi

if [[ -z "${config['github.jenkins.app-id']}" ]]; then
  echo "--- Required 'github.jenkins.app-id' property is not found"
  exit 1
fi

if [[ -z "${config['github.jenkins.private-key-file']}" ]]; then
  echo "--- Required 'github.jenkins.private-key-file' property is not found"
  exit 1
fi

if [[ -z "${config['domain.cert.private-key-file']}" && -z "${config['domain.cert.public-key-file']}" ]]; then
  echo "--- Certificates for '${config['domain.name']}' was not provided. Will be generated self-signed certs"
fi

echo "--- Infrastructure will be deployed in '$PROJECT_ID' project"

gsutil list -b gs://"$STATE_BUCKET_NAME"
if [ "$?" -eq 1 ]; then
  echo "--- Creating bucket '$STATE_BUCKET_NAME' for terraform state"
  gsutil mb gs://"$STATE_BUCKET_NAME"
  gsutil versioning set on gs://"${PROJECT_ID}"-tfstate
else
  echo "--- Terraform state bucket '$STATE_BUCKET_NAME' already exists"
fi

cd gke/ || exit

if ! type "terraform" >/dev/null; then
  echo "--- Terraform is not installed. Installing..."
  wget https://releases.hashicorp.com/terraform/1.0.10/terraform_1.0.10_linux_amd64.zip || exit 1
  unzip terraform_1.0.10_linux_amd64.zip || exit 1
  sudo mv terraform /usr/local/bin/
  rm terraform_1.0.10_linux_amd64.zip
fi

#FIXME fix terraform
gcloud services enable compute.googleapis.com || exit 1

terraform init \
  -backend-config="bucket=$STATE_BUCKET_NAME" \
  -var="tf-state-bucket=$STATE_BUCKET_NAME" ||
  exit 1

for i in "$@"; do
  if [[ $i == "-p" ]]; then
    echo "--- Running only terraform plan"
    terraform plan \
      -backend-config="bucket=$STATE_BUCKET_NAME" \
      -var="tf-state-bucket=$STATE_BUCKET_NAME" \
      -var="project_id=$PROJECT_ID" \
      -var="git-org-name=${config['github.organization.name']}" \
      -var="git-app-id=${config['github.jenkins.app-id']}" \
      -var="git-private-key=$(cat "${config['github.jenkins.private-key-file']}")" \
      -var="ingress_domain=${config['domain.name']}" \
      -var="ingress_domain_cert_public_key=${config['domain.cert.public-key-file']}" \
      -var="ingress_domain_cert_private_key=${config['domain.cert.private-key-file']}"

    echo "--- Remove terraform state bucket '$STATE_BUCKET_NAME' if you do not need it"
    exit 0
  fi
done

terraform apply -auto-approve \
  -var="tf-state-bucket=$STATE_BUCKET_NAME" \
  -var="project_id=$PROJECT_ID" \
  -var="git-org-name=${config['github.organization.name']}" \
  -var="git-app-id=${config['github.jenkins.app-id']}" \
  -var="git-private-key=$(cat "${config['github.jenkins.private-key-file']}")" \
  -var="ingress_domain=${config['domain.name']}" \
  -var="ingress_domain_cert_public_key=${config['domain.cert.public-key-file']}" \
  -var="ingress_domain_cert_private_key=${config['domain.cert.private-key-file']}" ||
  exit 1

echo "--- Terraform has been applied. Getting servers urls..."

export ZONE=$(terraform output -raw zone)
export CLUSTER_NAME=$(terraform output -raw cluster_name)
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${PROJECT_ID}
JENKINS_ADDRESS=$(terraform output -raw jenkins_domain)
JENKINS_IP=$(kubectl --namespace jenkins get ingress jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
JENKINS_PASSWORD=$(kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
GRAFANA_ADDRESS=$(terraform output -raw grafana_domain)
GRAFANA_IP=$(kubectl --namespace monitoring get ingress kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
GRAFANA_PASSWORD=$(kubectl --namespace monitoring get secret kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
SONAR_ADDRESS=$(terraform output -raw sonar_domain)
SONAR_IP=$(kubectl --namespace sonarqube get ingress sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo
printf "%-15s %30s %40s\n" "IP" "Address" "Credentials" \
  "$JENKINS_IP" "https://$JENKINS_ADDRESS" "admin/$JENKINS_PASSWORD" \
  "$GRAFANA_IP" "https://$GRAFANA_ADDRESS" "admin/$GRAFANA_PASSWORD" \
  "$SONAR_IP" "https://$SONAR_ADDRESS" "admin/admin"

echo
printf "Set A record in the provided domain to services IP. If you do not have the domain you can add mapping into host file\n"
