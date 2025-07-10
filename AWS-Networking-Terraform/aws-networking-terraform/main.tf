module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "aws_subnet" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_AZ = var.private_subnet_AZ
  public_subnet_AZ = var.public_subnet_AZ
}


module "aws_igw" {
  source = "./modules/internet_gateway"
  vpc_id = module.vpc.vpc_id
}

module "route_table" {
  source = "./modules/route_tables"
  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  aws_internet_gateway_id = module.aws_igw.igw_id
  public_subnet_cidr = module.aws_subnet.public_subnet_cidr
  public_route = var.public_route
  public_subnet_id = module.aws_subnet.public_subnet_id
  nat_gateway_id = module.nat_gateway.nat_gateway_id
  private_subnet_id = module.aws_subnet.private_subnet_id
}

module "security_group" {
  source = "./modules/security_group"
  vpc_cidr = [module.vpc.vpc_cidr]
  vpc_id = module.vpc.vpc_id
  public_route = [var.public_route]
}

module "nat_gateway" {
  source = "./modules/nat_gateway"
  public_subnet_id = module.aws_subnet.public_subnet_id
}