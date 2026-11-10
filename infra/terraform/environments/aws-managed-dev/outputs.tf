output "pipeline_name" {
  description = "AWS CodePipeline name"
  value       = aws_codepipeline.app.name
}

output "connection_status" {
  description = "CodeConnections status; complete the GitHub handshake before running the pipeline"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "ecr_repository_name" {
  description = "Private ECR repository name"
  value       = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch operations dashboard name"
  value       = aws_cloudwatch_dashboard.app.dashboard_name
}
