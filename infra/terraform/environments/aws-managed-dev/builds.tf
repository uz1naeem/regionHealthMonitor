resource "aws_cloudwatch_log_group" "quality" {
  name              = "/aws/codebuild/${var.name_prefix}-quality"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "container" {
  name              = "/aws/codebuild/${var.name_prefix}-container"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "infrastructure" {
  name              = "/aws/codebuild/${var.name_prefix}-infrastructure"
  retention_in_days = var.log_retention_days
}

resource "aws_codebuild_project" "quality" {
  name         = "${var.name_prefix}-quality"
  description  = "Runs application tests and dependency checks"
  service_role = aws_iam_role.quality_build.arn

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = 0.2
      phases = {
        install = {
          runtime-versions = { python = "3.11" }
          commands         = ["python -m pip install --upgrade pip", "pip install -r requirements.txt"]
        }
        build = {
          commands = ["pytest -v", "pip-audit -r requirements.txt"]
        }
      }
    })
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.quality.name
      stream_name = "build"
    }
  }
}

resource "aws_codebuild_project" "container" {
  name         = "${var.name_prefix}-container"
  description  = "Builds, scans and publishes the application image"
  service_role = aws_iam_role.container_build.arn

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = 0.2
      phases = {
        pre_build = {
          commands = [
            "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI",
            "export IMAGE_TAG=$(printf '%s' \"$CODEBUILD_RESOLVED_SOURCE_VERSION\" | cut -c1-12)"
          ]
        }
        build = {
          commands = [
            "docker build --pull -t $ECR_REPOSITORY_URI:$IMAGE_TAG .",
            "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock public.ecr.aws/aquasecurity/trivy:0.58.2 image --severity CRITICAL --exit-code 1 $ECR_REPOSITORY_URI:$IMAGE_TAG"
          ]
        }
        post_build = {
          commands = [
            "docker push $ECR_REPOSITORY_URI:$IMAGE_TAG",
            "printf '[{\"name\":\"health-monitor\",\"imageUri\":\"%s:%s\"}]' \"$ECR_REPOSITORY_URI\" \"$IMAGE_TAG\" > imagedefinitions.json"
          ]
        }
      }
      artifacts = {
        files = ["imagedefinitions.json"]
      }
    })
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.container.name
      stream_name = "build"
    }
  }
}

resource "aws_codebuild_project" "infrastructure" {
  name         = "${var.name_prefix}-infrastructure"
  description  = "Formats, validates and plans the managed AWS infrastructure"
  service_role = aws_iam_role.infrastructure_plan.arn

  source {
    type = "CODEPIPELINE"
    buildspec = yamlencode({
      version = 0.2
      phases = {
        install = {
          commands = [
            "export TERRAFORM_VERSION=1.9.8",
            "curl --fail --silent --show-error --location -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip",
            "echo '186e0145f5e5f2eb97cbd785bc78f21bae4ef15119349f6ad4fa535b83b10df8  /tmp/terraform.zip' | sha256sum --check",
            "unzip -q /tmp/terraform.zip -d /usr/local/bin",
            "terraform version"
          ]
        }
        build = {
          commands = [
            "terraform -chdir=infra/terraform/environments/aws-managed-dev fmt -check",
            "terraform -chdir=infra/terraform/environments/aws-managed-dev init -reconfigure -input=false -backend-config=\"bucket=$TF_STATE_BUCKET\" -backend-config=\"key=$TF_STATE_KEY\" -backend-config=\"region=$AWS_DEFAULT_REGION\" -backend-config=\"dynamodb_table=$TF_LOCK_TABLE\" -backend-config=\"encrypt=true\"",
            "terraform -chdir=infra/terraform/environments/aws-managed-dev validate",
            "terraform -chdir=infra/terraform/environments/aws-managed-dev plan -refresh=false -input=false -lock=false -out=tfplan"
          ]
        }
      }
    })
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_STATE_BUCKET"
      value = "rhm-tfstate-${data.aws_caller_identity.current.account_id}"
    }

    environment_variable {
      name  = "TF_STATE_KEY"
      value = "env/aws-managed-dev/terraform.tfstate"
    }

    environment_variable {
      name  = "TF_LOCK_TABLE"
      value = "rhm-tf-lock"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.infrastructure.name
      stream_name = "build"
    }
  }
}
