resource "aws_cloudwatch_metric_alarm" "failed_build" {
  alarm_name          = "${var.name_prefix}-failed-build"
  alarm_description   = "A managed pipeline CodeBuild project reported a failed build"
  namespace           = "AWS/CodeBuild"
  metric_name         = "FailedBuilds"
  dimensions          = { ProjectName = aws_codebuild_project.container.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "task_count" {
  alarm_name        = "${var.name_prefix}-task-count"
  alarm_description = "The Fargate service is below its configured desired task count"
  namespace         = "ECS/ContainerInsights"
  metric_name       = "RunningTaskCount"
  dimensions = {
    ClusterName = aws_ecs_cluster.app.name
    ServiceName = aws_ecs_service.app.name
  }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = max(var.service_desired_count, 1)
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = var.service_desired_count == 0 ? "notBreaching" : "breaching"
}

resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${var.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS service health"
          region = var.aws_region
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.app.name, "ServiceName", aws_ecs_service.app.name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", aws_ecs_cluster.app.name, "ServiceName", aws_ecs_service.app.name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CodeBuild results"
          region = var.aws_region
          metrics = [
            ["AWS/CodeBuild", "SucceededBuilds", "ProjectName", aws_codebuild_project.quality.name],
            [".", "FailedBuilds", ".", "."],
            ["AWS/CodeBuild", "SucceededBuilds", "ProjectName", aws_codebuild_project.container.name],
            [".", "FailedBuilds", ".", "."]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}
