# create vpc
# create 3 private subnets /24
# create 2 public subnets /24

# constraints:
# VPC CIDR needs to be > /21
# 

#VPC configuration
resource "aws_vpc" "main" {

  cidr_block = var.vpc_cidr

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
    Name        = "${var.vpc_name}-ig"
    Environment = var.environment
  }
}


# Route table association with public subnets and internet gateway
resource "aws_route_table_association" "task" {
  count          = length(var.pub_subnets_cidr)
  subnet_id      = element(aws_subnet.pub_subnets.*.id, count.index)
  route_table_id = aws_route_table.internet_gateway.id
}
