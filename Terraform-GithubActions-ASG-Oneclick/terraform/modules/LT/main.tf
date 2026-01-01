resource "aws_security_group" "ec2_SG" {
  name = "ec2-SG"
  description = "cdcsdcdc"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_SG.id
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = "ami-0645fa1a93d9dbe13"
  instance_type = "t3.micro"

  # Attach IAM Role
  iam_instance_profile {
    name = "ecr_role"
  }

  # Security Group
  vpc_security_group_ids = [
    aws_security_group.ec2_SG.id
  ]

  # Spot instances
  instance_market_options {
    market_type = "spot"

    spot_options {
      max_price = "0.03"
    }
  }

  # User Data (BASE64 encoded automatically by Terraform)
  user_data = base64encode(<<-EOF
    #!/bin/bash
    aws ecr get-login-password --region ****** | docker login --username AWS --password-stdin ******.dkr.ecr.******.amazonaws.com
    docker pull ******.dkr.ecr.******.amazonaws.com/******:latest
    docker run -d -p 80:80 --name docker-cont ******.dkr.ecr.******.amazonaws.com/******:latest
  EOF
  )
}
