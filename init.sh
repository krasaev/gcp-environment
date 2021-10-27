#!/bin/bash

# set current project
PROJECT_ID=$(gcloud config get-value project)

# create tf state bucket
gsutil mb gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://"${PROJECT_ID}"-tfstate

sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" ./example-pipelines/environments/*/terraform.tfvars
sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" ./example-pipelines/environments/*/backend.tf
sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" ./jenkins-gke/tf-gke/terraform.tfvars
sed -i.bak "s/PROJECT_ID/${PROJECT_ID}/g" ./jenkins-gke/tf-gke/backend.tf

wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_0.12.24_linux_amd64.zip

# cd jenkins-gke/tf-gke/
# terraform init
# terraform plan --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN"
# terraform apply --auto-approve --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN"