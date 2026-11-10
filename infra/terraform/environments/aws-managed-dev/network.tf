data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "workload" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.workload.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = { Name = "${var.name_prefix}-private-${count.index + 1}" }
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.workload.id
  tags   = { Name = "${var.name_prefix}-private-${count.index + 1}" }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "task" {
  name        = "${var.name_prefix}-task"
  description = "Fargate task security group with no inbound rules"
  vpc_id      = aws_vpc.workload.id

  tags = { Name = "${var.name_prefix}-task" }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-endpoints"
  description = "HTTPS access to private AWS service endpoints"
  vpc_id      = aws_vpc.workload.id

  tags = { Name = "${var.name_prefix}-endpoints" }
}

resource "aws_security_group_rule" "endpoint_https_from_task" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.task.id
  security_group_id        = aws_security_group.endpoints.id
  description              = "HTTPS from the Fargate task only"
}

resource "aws_security_group_rule" "task_https_to_endpoints" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.endpoints.id
  security_group_id        = aws_security_group.task.id
  description              = "HTTPS to interface endpoints"
}

resource "aws_security_group_rule" "task_dns_udp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.task.id
  description       = "DNS within the workload VPC"
}

resource "aws_security_group_rule" "task_dns_tcp" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.task.id
  description       = "TCP DNS fallback within the workload VPC"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.workload.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = { Name = "${var.name_prefix}-s3" }
}

resource "aws_security_group_rule" "task_https_to_s3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  security_group_id = aws_security_group.task.id
  description       = "HTTPS to Amazon S3 through its gateway endpoint"
}

locals {
  interface_endpoint_services = toset([
    "ecr.api",
    "ecr.dkr",
    "logs",
    "ec2",
    "lambda"
  ])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = aws_vpc.workload.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]

  tags = { Name = "${var.name_prefix}-${replace(each.value, ".", "-")}" }
}
