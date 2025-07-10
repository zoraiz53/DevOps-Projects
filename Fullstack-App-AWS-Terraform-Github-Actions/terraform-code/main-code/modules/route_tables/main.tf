resource "aws_route_table" "aws_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.internet_route
    gateway_id = var.aws_internet_gateway_id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = var.public_subnet_id
  route_table_id = aws_route_table.aws_rt.id
}

resource "aws_route_table" "aws_rt_2" {
  vpc_id = var.vpc_id

  route {
    cidr_block = var.internet_route
    nat_gateway_id = var.nat_gateway_id
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id = var.private_subnet_id
  route_table_id = aws_route_table.aws_rt_2.id
}
