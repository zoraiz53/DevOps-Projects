# -------------------------------
# Application Load Balancer
# -------------------------------
resource "aws_lb" "my_project_alb" {
  name               = "my-project-lb-1"
  internal           = false
  load_balancer_type = var.load_balancer_type
  security_groups    = [var.LB_security_group_id]
  subnets            = [
    var.subnet_1,
    var.subnet_2,
    var.subnet_3,
    var.subnet_4
  ]
}
# -------------------------------
# Target Group
# -------------------------------
resource "aws_lb_target_group" "my_project_tg" {
  name        = var.aws_lb_target_group_name
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 5
    matcher             = "200"
  }
}
# -------------------------------
# Listener (Port 80)
# -------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my_project_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.my_project_tg.arn
        weight = 1
      }
      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }
}
# -------------------------------
# Auto Scaling Group
# -------------------------------
resource "aws_autoscaling_group" "my_project_asg" {
  name                      = var.aws_autoscaling_group_name
  desired_capacity          = var.aws_asg_desired_capacity
  max_size                  = var.aws_asg_max_capacity
  min_size                  = var.aws_asg_min_capacity
  vpc_zone_identifier       = [
    var.subnet_1,
    var.subnet_2,
    var.subnet_3,
    var.subnet_4
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 30
  target_group_arns         = [aws_lb_target_group.my_project_tg.arn]
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 0
    }
  }
  tag {
    key                  = "Name"
    value                = var.asg_instance_name
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
