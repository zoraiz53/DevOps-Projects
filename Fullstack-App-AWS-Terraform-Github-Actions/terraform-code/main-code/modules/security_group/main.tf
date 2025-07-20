resource "aws_security_group" "security_group_frontend" {
  name        = "terraform_security_grp_frontend"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_all_fr_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.internet_route
  security_group_id = aws_security_group.security_group_frontend.id
}

resource "aws_security_group_rule" "allow_SSH" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ip_1, var.ip_2]
  security_group_id = aws_security_group.security_group_frontend.id
}

resource "aws_security_group_rule" "allow_port_3000" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.internet_route
  security_group_id = aws_security_group.security_group_frontend.id
}

resource "aws_security_group_rule" "allow_HTTP" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.internet_route
  security_group_id = aws_security_group.security_group_frontend.id
}

resource "aws_security_group_rule" "allow_HTTPS" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.internet_route
  security_group_id = aws_security_group.security_group_frontend.id
}

resource "aws_security_group" "security_group_backend" {
  name        = "terraform_security_grp_backend"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_all_bk_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.internet_route
  security_group_id = aws_security_group.security_group_backend.id
}

resource "aws_security_group_rule" "allow_SSH_bk" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ip_1, var.ip_2]
  security_group_id = aws_security_group.security_group_backend.id
}

resource "aws_security_group_rule" "allow_kb_5000" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  source_security_group_id = aws_security_group.security_group_frontend.id
  security_group_id = aws_security_group.security_group_backend.id
}