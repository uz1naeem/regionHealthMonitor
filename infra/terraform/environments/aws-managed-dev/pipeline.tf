resource "aws_codestarconnections_connection" "github" {
  name          = "${var.name_prefix}-github"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "app" {
  name     = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.pipeline.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.repository_owner}/${var.repository_name}"
        BranchName           = var.branch_name
        DetectChanges        = "true"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Application_Quality"

    action {
      name            = "Test_and_Audit"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.quality.name
      }
    }
  }

  stage {
    name = "Container_Build"

    action {
      name             = "Build_Scan_and_Push"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["ImageDefinitions"]

      configuration = {
        ProjectName = aws_codebuild_project.container.name
      }
    }
  }

  stage {
    name = "Infrastructure"

    action {
      name            = "Terraform_Plan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.infrastructure.name
      }
    }
  }

  stage {
    name = "ECS_Deploy"

    action {
      name            = "Deploy_Revision"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["ImageDefinitions"]

      configuration = {
        ClusterName = aws_ecs_cluster.app.name
        ServiceName = aws_ecs_service.app.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.codepipeline,
    aws_s3_bucket_public_access_block.pipeline_artifacts,
    aws_s3_bucket_server_side_encryption_configuration.pipeline_artifacts
  ]
}
