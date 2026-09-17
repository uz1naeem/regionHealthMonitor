variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "cluster_name" {
  type        = string
  description = "Name of the kind Kubernetes cluster"
}
variable "config_path" {
  type        = string
  description = "Path to write the generated kind cluster config"
}
