module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.6"

  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)
  id = module.vpc.private_subnets[count.index]
}

data "aws_subnet" "public_subnets" {
  count = length(var.public_subnets)
  id = module.vpc.public_subnets[count.index]
}

locals {
  private_subnets = flatten([
    for subnet in data.aws_subnet.private_subnets: [
      {
        subnet_id = subnet.id
        availability_zone = subnet.availability_zone
        type = "private"
      }
    ]
  ])
  private_subnets_id_to_zone = {
    for private_subnet in local.private_subnets:
      private_subnet.subnet_id => private_subnet.availability_zone
  }
  private_subnets_zone_to_id = {
    for private_subnet in local.private_subnets:
      private_subnet.availability_zone => private_subnet.subnet_id
  }
  public_subnets = flatten([
    for subnet in data.aws_subnet.public_subnets: [
      {
        subnet_id = subnet.id
        availability_zone = subnet.availability_zone
        type = "public"
      }
    ]
  ])
  public_subnets_id_to_zone = {
    for public_subnet in local.public_subnets:
      public_subnet.subnet_id => public_subnet.availability_zone
  }
  public_subnets_zone_to_id = {
    for public_subnet in local.public_subnets:
      public_subnet.availability_zone => public_subnet.subnet_id
  }
}

data "aws_vpc" "peer_vpc_list" {
  for_each = toset(var.peer_vpc_list)
  tags = {
    Name = each.value
  }
}

resource "aws_vpc_peering_connection" "peering_connections" {
  for_each    = data.aws_vpc.peer_vpc_list
  peer_vpc_id = each.value.id
  vpc_id      = module.vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "VPC-${var.vpc_name}-VPC-${each.value.tags.Name}"
  }

  accepter {
    allow_remote_vpc_dns_resolution  = true
    allow_classic_link_to_remote_vpc = false
    allow_vpc_to_remote_classic_link = false
  }

  requester {
    allow_remote_vpc_dns_resolution  = true
    allow_classic_link_to_remote_vpc = false
    allow_vpc_to_remote_classic_link = false
  }
}

locals {
  peering_connections_map = {
    for pc in aws_vpc_peering_connection.peering_connections:
      pc.peer_vpc_id => pc
  }
  peer_routes = tolist(flatten([
    for peer_vpc in data.aws_vpc.peer_vpc_list : [
      for route_table_id in concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids) : [
        {
          vpc                   = peer_vpc
          route_table_id        = route_table_id
          peering_connection_id = local.peering_connections_map[peer_vpc.id].id
        }
      ]
    ]
  ]))
}

resource "aws_route" "new_vpc_peering_routes" {
  count                     = length(local.peer_routes)
  route_table_id            = local.peer_routes[count.index].route_table_id
  destination_cidr_block    = local.peer_routes[count.index].vpc.cidr_block
  vpc_peering_connection_id = local.peer_routes[count.index].peering_connection_id
}

data "aws_subnet_ids" "peer_vpc_subnet_ids" {
  for_each = data.aws_vpc.peer_vpc_list
  vpc_id   = each.value.id
}

locals {
  peer_vpc_subnet_ids = flatten([
    for subnet_ids in data.aws_subnet_ids.peer_vpc_subnet_ids: [
      for subnet_id in subnet_ids.ids: [
        {
          subnet_id = subnet_id
          vpc_id = subnet_ids.vpc_id
        }
      ]
    ]
  ])
}

data "aws_route_table" "peering_route_tables" {
  count     = length(local.peer_vpc_subnet_ids)
  vpc_id    = local.peer_vpc_subnet_ids[count.index].vpc_id
  subnet_id = local.peer_vpc_subnet_ids[count.index].subnet_id
}

locals {
  peering_route_tables_map_tmp = {
    for table in data.aws_route_table.peering_route_tables:
      table.id => table.vpc_id...
  }
  peering_route_tables_map = {
    for table_id, vpc_ids in local.peering_route_tables_map_tmp:
      table_id => distinct(vpc_ids)[0]
  }
  peering_route_table_ids = toset(data.aws_route_table.peering_route_tables[*].id)
}

resource "aws_route" "peering_route" {
  for_each                  = local.peering_route_table_ids
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = local.peering_connections_map[local.peering_route_tables_map[each.value]].id
}
