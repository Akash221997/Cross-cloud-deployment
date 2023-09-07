#!/bin/bash

# This script takes 2 parameters Cloud_provider (aws or gcp) and Cluster_name
cd $BASE_PROJECT_PATH
PROVIDER=$1
rm -rf .terraform/terraform.tfstate
       terraform init -backend-config="prefix=$PROVIDER"
       #terraform init
       terraform destroy -var "cloud_provider=$1" -var "cluster_name=$2"
rm -rf .terraform 

