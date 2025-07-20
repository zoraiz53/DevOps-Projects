 resource "aws_internet_gateway" "aws_igw" {
   vpc_id = var.vpc_id
}