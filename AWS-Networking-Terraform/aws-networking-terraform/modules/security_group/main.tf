resource "aws_security_group" "security_group" {
  name        = "terraform_security_grp"
  description = "Allow SSH and HTTP inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_SSH" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.public_route
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_HTTP" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.public_route
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.security_group.id
  cidr_blocks       = var.public_route
}
