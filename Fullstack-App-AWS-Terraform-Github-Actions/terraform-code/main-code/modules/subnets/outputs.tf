output "private_subnet_cidr" {
  value = var.private_subnet_cidr_block
}

output "public_subnet_cidr" {
  value = var.public_subnet_cidr_block
}

output "private_subnet_AZ" {
  value = var.private_subnet_AZ 
}

output "public_subnet_AZ" {
  value = var.public_subnet_AZ
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}