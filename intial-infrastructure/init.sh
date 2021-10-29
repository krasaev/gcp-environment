#!/bin/bash

# set current project
PROJECT_ID=$(gcloud config get-value project)
STATE_BUCKET_NAME=${PROJECT_ID}-tfstate

# create tf state bucket
gsutil mb gs://"$STATE_BUCKET_NAME"
gsutil versioning set on gs://"${PROJECT_ID}"-tfstate

cd gke-jenkins/ || exit

wget https://releases.hashicorp.com/terraform/1.0.9/terraform_1.0.9_linux_amd64.zip
unzip terraform_1.0.9_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.0.9_linux_amd64.zip

terraform init -backend-config="bucket=$STATE_BUCKET_NAME" -var="project_id=$PROJECT_ID" -var="tf-state-bucket=$STATE_BUCKET_NAME"
# terraform plan --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN" -var="project_id=$PROJECT_ID"
# terraform apply --auto-approve --var "github_username=$GITHUB_USER" --var "github_token=$GITHUB_TOKEN"
#
#export JENKINS_PROJECT_ID=$(cd ../jenkins-gke/tf-gke && terraform output jenkins_project_id)
#export ZONE=$(cd ../jenkins-gke/tf-gke && terraform output zone)
#export CLUSTER_NAME=$(cd ../jenkins-gke/tf-gke && terraform output cluster_name)
#gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${JENKINS_PROJECT_ID}
#printf jenkins-username:admin;echo
#printf jenkins-password: ; printf $(kubectl get secret --namespace default jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
