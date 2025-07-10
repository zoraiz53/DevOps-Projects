terraform {
  backend "s3" {
    bucket         = "backend-bucket-123"
    key            = "/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "backend-state-locking-table"
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