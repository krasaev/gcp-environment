#!/bin/bash

if [ -z "$1" ]; then
    echo -e "\nPlease provide github organization name!\n"
    exit 1
fi

if [ -z "$2" ]; then
    echo -e "\nPlease provide github app id!\n"
    exit 1
fi

if [ -z "$2" ]; then
    echo -e "\nPlease provide github app private key!\n"
    exit 1
fi

GITHUB_ORG_NAME=$1
GITHUB_APP_ID=$2
GITHUB_PRIVATE_KEY=$3

# set current project
PROJECT_ID=$(gcloud config get-value project)
STATE_BUCKET_NAME=${PROJECT_ID}-tfstate

# create tf state bucket
gsutil mb gs://"$STATE_BUCKET_NAME"
gsutil versioning set on gs://"${PROJECT_ID}"-tfstate

cd gke-jenkins/ || exit 1

wget https://releases.hashicorp.com/terraform/1.0.10/terraform_1.0.10_linux_amd64.zip
unzip terraform_1.0.10_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.0.10_linux_amd64.zip

#FIXME fix terraform
gcloud services enable compute.googleapis.com

terraform init -backend-config="bucket=$STATE_BUCKET_NAME" -var="project_id=$PROJECT_ID" -var="git-org-nam=$GITHUB_ORG_NAME" -var="git-app-id=$GITHUB_APP_ID" -var="git-private-key=$GITHUB_PRIVATE_KEY" -var="tf-state-bucket=$STATE_BUCKET_NAME" || exit 1
terraform apply -auto-approve -var="project_id=$PROJECT_ID" -var="git-org-name=$GITHUB_ORG_NAME" -var="git-app-id=$GITHUB_APP_ID" -var="git-private-key=$GITHUB_PRIVATE_KEY" -var="tf-state-bucket=$STATE_BUCKET_NAME" || exit 1

export ZONE=$(terraform output -raw zone)
export CLUSTER_NAME=$(terraform output -raw cluster_name)
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${ZONE} --project=${PROJECT_ID}
JENKINS_IP=$(kubectl --namespace jenkins get service jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
JENKINS_PASSWORD=$(kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
printf "Jenkins url: http://$JENKINS_IP\nJenkins user: admin\nJenkins password: $JENKINS_PASSWORD\n"