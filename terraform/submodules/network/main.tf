# create vpc
# create 3 private subnets /24
# create 2 public subnets /24

# constraints:
# VPC CIDR needs to be > /21
# 

#VPC configuration
resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }
}

# Internet Gateway configuration
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }
}

# Public Subnets configuration
resource "aws_subnet" "pub_subnets" {

  count                   = length(var.pub_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.pub_subnets_cidr, count.index)
  availability_zone       = element(var.pub_subnets_azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.vpc_name}-pub-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "prv_subnets" {

  count             = length(var.prv_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.prv_subnets_cidr, count.index)
  availability_zone = element(var.prv_subnets_azs, count.index)

  tags = {
    Name        = "${var.vpc_name}-prv-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

# Route Table configuration
# The VPC 'local' route table will be created automatically
resource "aws_route_table" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.environment
  }
}

# Route table association with public subnets and internet gateway
resource "aws_route_table_association" "igw" {
  count          = length(var.pub_subnets_cidr)
  subnet_id      = element(aws_subnet.pub_subnets.*.id, count.index)
  route_table_id = aws_route_table.internet_gateway.id
}


# Nat Gateway configuration

resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.pub_subnets)
  allocation_id = aws_eip.ngw.*.id[count.index]
  subnet_id     = aws_subnet.pub_subnets.*.id[count.index]
}

resource "random_integer" "ngw_index" {
  min = 0
  max = length(aws_nat_gateway.main)
}

resource "aws_eip" "ngw" {
  count = length(aws_subnet.pub_subnets)
  vpc   = true
}

resource "aws_route_table" "ngw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.vpc_name}-ngw"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "ngw" {
  count          = length(var.prv_subnets_cidr)
  subnet_id      = element(aws_subnet.prv_subnets.*.id, count.index)
  route_table_id = aws_route_table.ngw.id
}

resource "aws_route" "ngw" {

  route_table_id         = aws_route_table.ngw.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = element(aws_nat_gateway.main.*.id, random_integer.ngw_index.result)
}
