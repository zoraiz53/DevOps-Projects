terraform {
  backend "s3" {
    bucket         = var.backend_bucket_name
    key            = var.dynamodb_key_name
    region         = var.region
    dynamodb_table = var.dynamodb_table_name
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ecr_access_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach the AmazonEC2ContainerRegistryReadOnly policy
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ecr_profile" {
  name = "ecr-instance-profile"
  role = aws_iam_role.ecr_access_role.name
}

resource "aws_security_group" "web_sg" {
  name        = var.instance_security_group_name
  description = "Allow HTTP access from anywhere (replace with ALB SG later)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template with IAM Instance Profile
resource "aws_launch_template" "web_LT" {
  name_prefix   = var.launch_template_name
  image_id      = var.launch_template_image_id
  instance_type = var.launch_template_instance_type

  # Force new version on ANY change
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecr_profile.arn
  }

  instance_market_options {
    market_type = "spot"
  }

  user_data = base64encode(<<EOF
#!/bin/bash
# Install Docker + AWS CLI (as before)
sudo apt-get update -y
sudo apt-get install -y docker.io curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Login to ECR (IAM Role provides permissions)
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 084828598848.dkr.ecr.us-east-1.amazonaws.com

# Pull & Run the image
sudo docker pull 084828598848.dkr.ecr.us-east-1.amazonaws.com/my-app-image:latest
sudo docker run -d -p 80:80 084828598848.dkr.ecr.us-east-1.amazonaws.com/my-app-image:latest
echo "New Template jjjkjkjkndsnccjnjcnjdsknckjdsncndscjdsck"
EOF
  )
}