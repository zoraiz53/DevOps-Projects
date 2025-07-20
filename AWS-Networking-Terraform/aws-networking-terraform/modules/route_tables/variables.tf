variable "vpc_id" {
  description = "vpc_id"
  type = string
}

variable "vpc_cidr" {
  description = "vpc_cidr"
  type = string
}

variable "aws_internet_gateway_id" { 
  description = "aws_internet_gateway_id"
  type = string
}

variable "public_subnet_cidr" {
}

variable "public_route" {
}

variable "public_subnet_id" {
}

variable "nat_gateway_id" {
}

variable "private_subnet_id" {
}