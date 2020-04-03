#!/bin/bash

ecr_repositories=$(aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | tr '\n' ',' | head -c -1)
terraform plan -var "ecr_repositories=$ecr_repositories" -out clean-plan .
