#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)
STATE_BUCKET_NAME=${PROJECT_ID}-tfstate

cd gke-jenkins/ || exit 1

terraform destroy -var="project_id=$PROJECT_ID" -var="git-org-name=empty" -var="git-app-id=empty" -var="git-private-key=empty" -var="tf-state-bucket=empty" || exit 1

gsutil rm -raf gs://"$STATE_BUCKET_NAME"
