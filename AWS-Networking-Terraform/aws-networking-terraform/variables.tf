variable "vpc_cidr" {
}

variable "private_subnet_cidr" {
}

variable "public_subnet_cidr" {
}

variable "public_subnet_AZ" { 
}

variable "private_subnet_AZ" { 
}

variable "public_route" {
}

variable "aws_region" {
  type = string
  description = "aws_region"
  default = "plz provide a value for the 'aws_region variable in provider.tf fle'"
}