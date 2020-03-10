variable "region" {
  default = "eu-west-1"
  type    = string
}

variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  type    = list(string)
}

variable "environment" {
  default = "preprod"
  type    = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "private_subnets" {
  default = []
  type    = list(string)
}

variable "public_subnets" {
  default = []
  type    = list(string)
}

variable "enable_nat_gateway" {
  default = true
  type    = bool
}

variable "single_nat_gateway" {
  default = false
  type    = bool
}

variable "enable_dns_hostnames" {
  default = true
  type    = bool
}

variable "peer_vpc_list" {
  default = ["DEFAULT"]
  type    = list(string)
}

variable "cluster_name" {
  type = string
}

variable "ssh_key_name" {
  default = "onering"
  type    = string
}

variable "node_auto_scaling_group_max_size" {
  type    = number
  default = 1
}

variable "node_auto_scaling_group_min_size" {
  type    = number
  default = 1
}

variable "node_auto_scaling_group_desired_capacity" {
  type    = number
  default = 1
}

variable "node_group_name" {
  type = string
}

variable "node_ami_type" {
  default = "AL2_x86_64"
  type = string
}

variable "node_instance_type" {
  default = "t3.small"
  type    = string
}

variable "node_volume_size" {
  default = 20
  type    = number
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "manage_cluster_iam_resources" {
  description = "Whether to let the module manage cluster IAM resources. If set to false, cluster_iam_role_name must be specified."
  type        = bool
  default     = true
}

variable "cluster_iam_role_name" {
  description = "IAM role name for the cluster. Only applicable if manage_cluster_iam_resources is set to false."
  type        = string
  default     = ""
}
