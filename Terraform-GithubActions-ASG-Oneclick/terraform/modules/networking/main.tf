#VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
}

#-----------------------------

# IGW

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc.id
}

#-----------------------------

# SUBNETS

resource "aws_subnet" "private_subnets" {
  count = 2
  vpc_id =  aws_vpc.vpc.id
  cidr_block = var.private_subnets_cidr[count.index]
  availability_zone = var.private_subnets_AZ[count.index]
}

resource "aws_subnet" "public_subnets" {
  count = 2
  vpc_id =  aws_vpc.vpc.id
  cidr_block = var.public_subnets_cidr[count.index]
  availability_zone = var.public_subnets_AZ[count.index]
}

#-----------------------------

# Route Tables and Subnet Associations

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_rt_route" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "public_subnet_association" {
  count = 2
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table_association" "private_subnet_association" {
  count = 2
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.private_subnets[count.index].id
}

#-----------------------------

# NAT GATEWAY

resource "aws_eip" "nat_eip" {
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnets[1].id
}

#-----------------------------

