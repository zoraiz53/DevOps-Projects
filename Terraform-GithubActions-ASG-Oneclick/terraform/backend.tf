terraform {
  backend "s3" {
    bucket         = "******"
    key            = "global/terraform.tfstate"
    region         = "******"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
