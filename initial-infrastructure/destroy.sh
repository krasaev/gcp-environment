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

cd gke/ || exit 1

terraform destroy \
  -var="tf-state-bucket=$STATE_BUCKET_NAME" \
  -var="project_id=$PROJECT_ID" \
  -var="git-org-name=${config['github.organization.name']}" \
  -var="git-app-id=${config['github.jenkins.app-id']}" \
  -var="git-private-key=$(cat "${config['github.jenkins.private-key-file']}")" \
  -var="ingress_domain=${config['domain.name']}" \
  -var="ingress_domain_cert_public_key=${config['domain.cert.public-key-file']}" \
  -var="ingress_domain_cert_private_key=${config['domain.cert.private-key-file']}" ||
  exit 1
gsutil rm -raf gs://"$STATE_BUCKET_NAME"
