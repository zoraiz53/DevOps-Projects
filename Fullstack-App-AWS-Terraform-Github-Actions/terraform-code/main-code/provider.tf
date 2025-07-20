terraform {
  backend "s3" {
    bucket         = "zoz-tf-state"
    key            = "webapp/terraform.tfstate"
    region         = "<DEPLOYMENT_REGION>"
    dynamodb_table = "<TERRAFORM_STATE_LOCKING_TABLE>"
    encrypt        = true
  }

  required_providers {
    aws = {
    source = "hashicorp/aws"
    version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}