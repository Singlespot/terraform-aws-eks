//output "default_route_table_id" {
//  value = module.vpc.default_route_table_id
//}
//
//output "private_route_table_ids" {
//  value = module.vpc.private_route_table_ids
//}
//
//output "public_route_table_ids" {
//  value = module.vpc.public_route_table_ids
//}
//
//output "peering_connections_map" {
//  value = local.peering_connections_map
//}
//
//output "peer_routes" {
//  value = local.peer_routes
//}

//output "peer_vpc_subnet_ids" {
//  value = local.peer_vpc_subnet_ids
//}
//
//output "peering_route_tables_map_tmp" {
//  value = local.peering_route_tables_map_tmp
//}
//
//output "peering_route_tables_map" {
//  value = local.peering_route_tables_map
//}
//
//output "peering_route_table_ids" {
//  value = local.peering_route_table_ids
//}

output "node_groups" {
  value = module.eks.node_groups
}

//output "workers_asg_names" {
//  value = module.eks.workers_asg_names
//}
//
//output "workers_launch_template_ids" {
//  value = module.eks.workers_launch_template_ids
//}
//
//output "desired_capacity" {
//  value = data.aws_autoscaling_group.asg.desired_capacity
//}
//
//output "aws_launch_template" {
//  value = data.aws_launch_template.lt.id
//}

output "private_subnets_id_to_zone" {
  value = local.private_subnets_id_to_zone
}

output "private_subnets_zone_to_id" {
  value = local.private_subnets_zone_to_id
}

output "public_subnets_id_to_zone" {
  value = local.public_subnets_id_to_zone
}

output "public_subnets_zone_to_id" {
  value = local.public_subnets_zone_to_id
}

output "autoscaling_groups" {
  value = data.aws_autoscaling_group.autoscaling_groups_updated
}

//output "launch_templates" {
//  value = data.aws_launch_template.launch_templates
//}

//output "launch_templates" {
//  value = aws_launch_template.launch_templates
//}
