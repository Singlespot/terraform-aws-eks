terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
//  version = ">= 2.28.1"
  version = ">= 2.53"
  region  = var.region
}

locals {
  ecr_repositories = split(",", var.ecr_repositories)
}

resource "aws_ecr_lifecycle_policy" "untagged_removal_policy" {
  count = length(local.ecr_repositories)
//  depends_on = ["aws_ecr_repository.ecr_repositories"]
  repository = local.ecr_repositories[count.index]

  policy = <<EOF
  {
  "rules": [
      {
          "rulePriority": 1,
          "description": "Expire Docker images older than 7 days",
          "selection": {
              "tagStatus": "untagged",
              "countType": "sinceImagePushed",
              "countUnit": "days",
              "countNumber": 7
          },
          "action": {
              "type": "expire"
          }
      }
  ]
  }
  EOF
}
