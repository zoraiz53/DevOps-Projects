variable "region" {
    description = "default-region"
    type = string
    default = "us-east-1"
}
variable "load_balancer" {
    description = "lb_name"
    type = string
    default = "my-project-lb-1"
}

variable "load_balancer_type" {
    description = "load_balancer_type"
    type = string
    default = "application"
}

variable "LB_security_group_id" {
    description = "LB_security_group_id"
    type = string
    default = "<SG_ID>"
}

variable "aws_lb_target_group_name" {
    description = "aws_lb_target_group_name"
    type = string
    default = "my-project-tg-2"
}

variable "vpc_id" {
    description = "vpc_id"
    type = string
    default = "<VPC_ID>"
}

variable "health_check_path" {
    description = "health_check_path"
    type = string
    default = "/"
}

variable "aws_autoscaling_group_name" {
    description = "aws_autoscaling_group_name"
    type = string
    default = "my-project-asg-1"
}

variable "aws_asg_desired_capacity" {
    description = "aws_asg_desired_capacity"
    type = number
    default = 1
}

variable "aws_asg_min_capacity" {
    description = "aws_asg_min_capacity"
    type = number
    default = 0
}

variable "aws_asg_max_capacity" {
    description = "aws_asg_max_capacity"
    type = number
    default = 2
}

variable "subnet_1" {
    description = "subnet_1"
    type = string
    default = "<SUBNET_1_ID>"
}

variable "subnet_2" {
    description = "subnet_2"
    type = string
    default = "SUBNET_2_ID"
}

variable "subnet_3" {
    description = "subnet_3"
    type = string
    default = "SUBNET_3_ID"
}

variable "subnet_4" {
    description = "subnet_4"
    type = string
    default = "SUBNET_3_ID"
}

variable "launch_template_id" {
    description = "launch_template_id"
    type = string
    default = "<LAUNCH_TEMPLATE_ID>"
}

variable "asg_instance_name" {
    description = "asg_instance_name"
    type = string
    default = "my-project-asg-instance"
}

variable "backend_bucket_name" {
  description = "backend_bucket_name"
  type = string
  default = "my-project-asg-instance"
}


variable "dynamodb_table_name" {
  description = "dynamodb_table_name"
  type = string
  default = "terraform-state-locking"
}


variable "dynamodb_key_name" {
  description = "dynamodb_key_name"
  type = string
  default = "webapp/terraform.tfstate"
}

variable "iam_role_name" {
  description = "iam_role_name"
  type = string
  default = "ecr-access-role"
}

variable "instance_security_group_name" {
  description = "aws_security_group_name"
  type = string
  default = "web-sg"
}

variable "launch_template_name" {
  description = "aws_launch_template_name"
  type = string
  default = "my-project-template"
}

variable "launch_template_image_id" {
  description = "launch_template_image_id"
  type = string
  default = "ami-020cba7c55df1f615" #Ubuntu 24.04 ID
}

variable "launch_template_instance_type" {
  description = "launch_template_instance_type"
  type = string
  default = "t2.micro"
}
