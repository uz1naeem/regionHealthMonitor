variable "aws_region" {
  type        = string
  description = "AWS Region for the managed development environment"
  default     = "eu-west-1"
}

variable "name_prefix" {
  type        = string
  description = "Prefix applied to AWS resource names"
  default     = "rhm-managed-dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the private workload VPC"
  default     = "10.30.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR ranges for the two private workload subnets"
  default     = ["10.30.1.0/24", "10.30.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs must be supplied."
  }
}

variable "repository_owner" {
  type        = string
  description = "GitHub organisation or user that owns the source repository"
}

variable "repository_name" {
  type        = string
  description = "GitHub source repository name"
  default     = "regionHealthMonitor"
}

variable "branch_name" {
  type        = string
  description = "Branch monitored by AWS CodePipeline"
  default     = "main"
}

variable "container_port" {
  type        = number
  description = "Container-only application port; no inbound rule publishes it"
  default     = 8080
}

variable "service_desired_count" {
  type        = number
  description = "Fargate task count. Keep at zero until the bootstrap image exists in ECR."
  default     = 0
}

variable "log_retention_days" {
  type        = number
  description = "Retention period for build and application logs"
  default     = 30
}
