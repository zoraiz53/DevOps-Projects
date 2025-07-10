resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id = var.public_subnet_id
  allocation_id = aws_eip.nat_eip.id
}