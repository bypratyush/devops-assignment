# VPC -> subnets -> internet gateway -> route table -> association
#
# Every link below is an implicit dependency: referencing aws_vpc.main.id
# tells Terraform the VPC must exist first, without any depends_on.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # instances get public DNS names

  tags = { Name = "${var.project_name}-vpc" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true # instances here get a public IP automatically

  tags = { Name = "${var.project_name}-public-a", Tier = "public" }
}

# No NAT gateway on purpose (about USD 33/month + data charges). Anything
# placed here can talk inside the VPC but cannot reach the internet.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "${var.project_name}-private-a", Tier = "private" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

# What makes a subnet "public" is exactly this: a 0.0.0.0/0 route to an IGW.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# The private subnet is not associated with any custom table, so it uses the
# VPC's main route table, which only has the "local" route.
