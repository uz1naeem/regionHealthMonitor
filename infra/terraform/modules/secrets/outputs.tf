output "registry_password_arn" {
  description = "ARN of the stored registry credential parameter (value not exposed)"
  value       = aws_ssm_parameter.registry_password.arn
}

output "app_secret_arn" {
  description = "ARN of the runtime application secret parameter (value not exposed)"
  value       = data.aws_ssm_parameter.app_secret.arn
}
