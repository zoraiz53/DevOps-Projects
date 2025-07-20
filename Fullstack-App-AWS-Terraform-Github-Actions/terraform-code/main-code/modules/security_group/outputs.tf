output "frontend_security_group_id" {
  value = aws_security_group.security_group_frontend.id
}

output "backend_security_group_id" {
  value = aws_security_group.security_group_backend.id
}