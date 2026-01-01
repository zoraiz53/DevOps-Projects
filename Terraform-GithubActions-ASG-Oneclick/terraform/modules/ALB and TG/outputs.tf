output "ALB_arn" {
  value = aws_lb.ALB.arn
}

output "ALB_SG_id" {
  value = aws_security_group.ALB_SG.id
}

output "ALB_TG_arn" {
  value = aws_lb_target_group.ALB_TG.arn
}