terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "<DEPLOYMENT_REGION>"
}

resource "aws_s3_bucket" "terrafrom_state" {
  bucket        = "<TERRAFORM_BACKEND_BUCKET>"
  force_destroy = true
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name          = "<TERRAFORM_STATE_LOCKING_TABLE>"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

