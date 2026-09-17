variable "name_prefix" {
  type        = string
  description = "Prefix applied to the SSM parameter names for this environment"
}

variable "registry_password" {
  type        = string
  description = "Docker registry password for the CI/CD pipeline. Supplied at runtime (TF_VAR_registry_password) or from Jenkins Credentials Manager, never committed to source control."
  sensitive   = true
}
