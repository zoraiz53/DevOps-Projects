variable "resource_group_name" {
  description = "the name of the resource group in which you are creating resources"
}

variable "vnet_name" {
  description = "virtual network name"
}

variable "vnet_address_space" {
  description = "virtual network address space"
}

variable "public_subnet_name" {
  description = "name of the public subnet"
}

variable "private_subnet_name" {
  description = "name of the private subnet"
}

variable "public_subnet_address_space" {
  description = "address prefixes for the public subnet"
}

variable "private_subnet_address_space" {
  description = "address prefixes for the public subnet"
}

variable "nat_gateway_name" {
  description = "name of the NAT gateway"
}

variable "nsg_for_public_subnet_name" {
  description = "name of the network security group for the public subnet"
}

variable "nsg_for_private_subnet_name" {
  description = "name of the network security group for the private subnet"
}