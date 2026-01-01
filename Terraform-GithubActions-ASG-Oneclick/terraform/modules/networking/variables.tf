variable "vpc_cidr_block" {
}

variable "private_subnets_cidr" {
}

variable "private_subnets_AZ" {
  type = list(string)
}

variable "public_subnets_cidr" {
}

variable "public_subnets_AZ" {
}
