# NETWORKING

module "networking" {
  source = "./modules/networking"
  vpc_cidr_block = var.vpc_cidr_block
  private_subnets_AZ = var.private_subnets_AZ
  public_subnets_AZ = var.public_subnets_AZ
  private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr = var.public_subnets_cidr
}

# ALB and Target Grp

module "ALB_and_TG" {
  source = "./modules/ALB and TG"
  vpc_id = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
} 

# Launch Template Creation

module "LT" {
  source = "./modules/LT"
  ALB_SG_id = module.ALB_and_TG.ALB_SG_id
  vpc_id = module.networking.vpc_id
}

# AutoScaling Grp

module "ASG" {
  source = "./modules/ASG"
  private_subnet_ids = module.networking.private_subnet_ids
  LT_id = module.LT.LT_id
  ALB-TG_arn = module.ALB_and_TG.ALB_TG_arn
}