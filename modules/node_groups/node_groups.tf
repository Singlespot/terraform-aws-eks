resource "aws_eks_node_group" "workers" {
  count = var.node_groups_count

  node_group_name = lookup(local.node_groups_expanded_values[count.index], "name", join("-", [var.cluster_name, local.node_groups_expanded_keys[count.index], random_pet.node_groups[count.index].id]))

  cluster_name  = var.cluster_name
  node_role_arn = local.node_groups_expanded_values[count.index]["iam_role_arn"]
  subnet_ids    = local.node_groups_expanded_values[count.index]["subnets"]

  scaling_config {
    desired_size = local.node_groups_expanded_values[count.index]["desired_capacity"]
    max_size     = local.node_groups_expanded_values[count.index]["max_capacity"]
    min_size     = local.node_groups_expanded_values[count.index]["min_capacity"]
  }

  ami_type        = lookup(local.node_groups_expanded_values[count.index], "ami_type", null)
  disk_size       = lookup(local.node_groups_expanded_values[count.index], "disk_size", null)
  instance_types  = [local.node_groups_expanded_values[count.index]["instance_type"]]
  release_version = lookup(local.node_groups_expanded_values[count.index], "ami_release_version", null)

  dynamic "remote_access" {
    for_each = local.node_groups_expanded_values[count.index]["key_name"] != "" ? [{
      ec2_ssh_key               = local.node_groups_expanded_values[count.index]["key_name"]
      source_security_group_ids = lookup(local.node_groups_expanded_values[count.index], "source_security_group_ids", [])
    }] : []

    content {
      ec2_ssh_key               = remote_access.value["ec2_ssh_key"]
      source_security_group_ids = remote_access.value["source_security_group_ids"]
    }
  }

  version = lookup(local.node_groups_expanded_values[count.index], "version", null)

  labels = merge(
    lookup(var.node_groups_defaults, "k8s_labels", {}),
    lookup(var.node_groups[local.node_groups_expanded_keys[count.index]], "k8s_labels", {})
  )

  tags = merge(
    var.tags,
    lookup(var.node_groups_defaults, "additional_tags", {}),
    lookup(var.node_groups[local.node_groups_expanded_keys[count.index]], "additional_tags", {}),
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }
}
