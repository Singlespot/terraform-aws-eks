variable "region" {
  default = "eu-west-1"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "268324876595",
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::268324876595:user/sebastien.demelo"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::268324876595:user/marc"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::268324876595:user/guillaume.gillet"
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::268324876595:user/laurent.chriqui"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]
}
