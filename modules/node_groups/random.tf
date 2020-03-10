resource "random_pet" "node_groups" {
  count = var.node_groups_count

  separator = "-"
  length    = 2

  keepers = {
    ami_type      = lookup(local.node_groups_expanded_values[count.index], "ami_type", null)
    disk_size     = lookup(local.node_groups_expanded_values[count.index], "disk_size", null)
    instance_type = local.node_groups_expanded_values[count.index]["instance_type"]
    iam_role_arn  = local.node_groups_expanded_values[count.index]["iam_role_arn"]

    key_name = local.node_groups_expanded_values[count.index]["key_name"]

    source_security_group_ids = join("|", compact(
      lookup(local.node_groups_expanded_values[count.index], "source_security_group_ids", [])
    ))
    subnet_ids      = join("|", local.node_groups_expanded_values[count.index]["subnets"])
    node_group_name = join("-", [var.cluster_name, local.node_groups_expanded_keys[count.index]])
  }
}
