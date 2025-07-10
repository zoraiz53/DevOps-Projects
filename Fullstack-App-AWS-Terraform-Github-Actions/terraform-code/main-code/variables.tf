variable "vpc_cidr" {
}

variable "private_subnet_cidr_block" {
}

variable "public_subnet_cidr_block" {
}

variable "public_subnet_AZ" { 
}

variable "private_subnet_AZ" { 
}

variable "internet_route" {
}

variable "aws_region" {
  type = string
  description = "aws_region"
  default = "plz provide a value for the 'aws_region variable in provider.tf fle'"
}

variable "hadi_ip" {
}

variable "zoraiz_ip" {
}