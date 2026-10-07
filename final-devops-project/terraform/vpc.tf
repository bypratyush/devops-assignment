# VPC with a public and a private subnet in each of two AZs.
#
#   public  10.20.1.0/24 (a)  10.20.2.0/24 (b)   -> route 0.0.0.0/0 to the IGW
#   private 10.20.11.0/24 (a) 10.20.12.0/24 (b)  -> no internet route, unless
#                                                   enable_eks adds a NAT gateway

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # EKS nodes need DNS hostnames to register

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${substr(var.availability_zones[count.index], -1, 1)}"
    # the AWS load balancer controller puts internet-facing ELBs here
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.project_name}-private-${substr(var.availability_zones[count.index], -1, 1)}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ---- public routing --------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---- private routing -------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Worker nodes in private subnets still have to pull images (ECR, GHCR) and
# reach the EKS API, so with EKS on they get one NAT gateway (in AZ a, to keep
# the cost to a single ~0.056 USD/hour gateway rather than one per AZ).
resource "aws_eip" "nat" {
  count  = var.enable_eks ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_eks ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${var.project_name}-nat" }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "private_nat" {
  count                  = var.enable_eks ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# ---- worker node security group --------------------------------------------

resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-eks-nodes"
  description = "EKS worker nodes: node-to-node traffic and the control plane"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-eks-nodes" }
}

# Pod and node traffic between workers. No description on this one: LocalStack
# 4.14 drops the description of an SG-to-SG rule, so every plan wanted to put
# it back (a permanent diff). Real AWS keeps it.
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_kubelet" {
  security_group_id = aws_security_group.nodes.id
  description       = "kubelet API from the control plane ENIs in the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_ingress_rule" "nodes_webhooks" {
  security_group_id = aws_security_group.nodes.id
  description       = "Admission webhooks (e.g. ingress-nginx) called by the control plane"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.nodes.id
  description       = "Image pulls, EKS API, S3 backups"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
