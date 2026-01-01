# -----------------------------
# ALB Security Group
# -----------------------------
resource "aws_security_group" "ALB_SG" {
  name        = "SG-for-ALB"
  description = "Allow traffic to ALB"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_HTTP" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ALB_SG.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  security_group_id = aws_security_group.ALB_SG.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}




# -----------------------------
# Target Group
# -----------------------------
resource "aws_lb_target_group" "ALB_TG" {
  name        = "ATP-ALB-TG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# -----------------------------
# ALB
# -----------------------------
resource "aws_lb" "ALB" {
  name               = "ATP-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_SG.id]
  subnets            = var.public_subnet_ids
}

# Listener: ALB listens on port 80
resource "aws_lb_listener" "ALB_listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALB_TG.arn
  }
}
