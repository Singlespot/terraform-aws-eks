terraform {
  required_version = ">= 0.12.6"
}

provider "aws" {
//  version = ">= 2.28.1"
  version = ">= 2.53"
  region  = var.region
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                    = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate  = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                   = data.aws_eks_cluster_auth.cluster.token
  load_config_file        = false
  // version              = "~> 1.10"
  version                 = "1.10.0"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  keepers = {
    disk_size         = var.node_volume_size
    key_name          = var.ssh_key_name
    ami_type          = var.node_ami_type
    instance_type     = var.node_instance_type
  }
}

locals {
  node_groups = {
    for subnet in concat(local.private_subnets, local.public_subnets):
      "ng-${subnet.type}-${subnet.availability_zone}-${random_string.suffix.result}" => {
        name              = "${var.node_group_name}-${subnet.type}-${subnet.availability_zone}-${random_string.suffix.result}"
        desired_capacity  = var.node_auto_scaling_group_desired_capacity
        max_capacity      = var.node_auto_scaling_group_max_size
        min_capacity      = var.node_auto_scaling_group_min_size
        subnets           = [subnet.subnet_id]
        disk_size         = var.node_volume_size
        key_name          = var.ssh_key_name
        ami_type          = var.node_ami_type
        instance_type     = var.node_instance_type
        k8s_labels = {
          Environment = var.environment
        }
        additional_tags = {
          Environment = var.environment
          AvailabilityZone = subnet.availability_zone
        }
      }
  }
}

locals {
  az_count = length(var.availability_zones)
  public_subnets_count = length(var.public_subnets)
  private_subnets_count = length(var.private_subnets)
  public_node_groups_count = (local.public_subnets_count > 0 ? min(local.public_subnets_count, local.az_count) : 0)
  private_node_groups_count = (local.private_subnets_count > 0 ? min(local.private_subnets_count, local.az_count) : 0)
  node_groups_count = local.public_node_groups_count + local.private_node_groups_count
}

module "eks" {
  source          = "../modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = module.vpc.public_subnets
//  enable_irsa     = true

  tags = {
    Environment = var.environment
  }

  vpc_id = module.vpc.vpc_id

  manage_cluster_iam_resources = var.manage_cluster_iam_resources
  cluster_iam_role_name        = var.cluster_iam_role_name

  node_groups = local.node_groups
  node_groups_count = local.node_groups_count

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts
}

data "aws_autoscaling_group" "autoscaling_groups" {
  count = local.node_groups_count
  name = module.eks.node_groups[count.index].resources[0].autoscaling_groups[0].name
}

locals {
  ngs   = module.eks.node_groups
  asgs  = data.aws_autoscaling_group.autoscaling_groups
  instances = data.aws_autoscaling_group.autoscaling_groups[*].instances
}

resource "null_resource" "autoscaling_groups_add_tags" {
  count = local.node_groups_count
  triggers = {
    asg_name = local.asgs[count.index].name
  }

  provisioner "local-exec" {
    command = "aws autoscaling create-or-update-tags --tags ResourceId=${local.asgs[count.index].name},ResourceType=auto-scaling-group,Key=Name,Value=${local.ngs[count.index].node_group_name},PropagateAtLaunch=true"
  }
}

resource "null_resource" "instances_add_tags" {
  count = local.node_groups_count
  triggers = {
    instance_names = join(" ", local.instances[count.index])
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${join(" ", local.instances[count.index])} --tags Key=Name,Value=${local.ngs[count.index].node_group_name}"
  }
}

//data "aws_autoscaling_group" "autoscaling_groups_updated" {
//  count = local.node_groups_count
//  depends_on = [null_resource.autoscaling_groups_add_tags]
//  name = module.eks.node_groups[count.index].resources[0].autoscaling_groups[0].name
//}
