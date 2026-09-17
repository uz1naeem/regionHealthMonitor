terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Store the Docker registry credential in SSM Parameter Store as an encrypted
# SecureString. The value is taken from a variable marked `sensitive`, so it is
# never rendered in plan output or in state file diffs.
resource "aws_ssm_parameter" "registry_password" {
  name        = "/rhm/${var.name_prefix}/registry-password"
  description = "Docker registry password for the CI/CD pipeline"
  type        = "SecureString"
  value       = var.registry_password
}

# Read a runtime application secret that is managed outside Terraform (created and
# rotated by the platform team) back from SSM Parameter Store via a data source.
# This keeps the secret value out of the codebase and the state file entirely.
data "aws_ssm_parameter" "app_secret" {
  name            = "/rhm/${var.name_prefix}/app-secret"
  with_decryption = true
}
