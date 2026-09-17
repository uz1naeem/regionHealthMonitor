variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names in this environment"
}
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the environment VPC"
}
variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}
variable "availability_zone" {
  type        = string
  description = "Availability zone for the subnet"
}
variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR permitted to reach SSH and the application port"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type for the environment"
}
variable "key_name" {
  type        = string
  description = "Name of the EC2 key pair for SSH access"
}
variable "cluster_name" {
  type        = string
  description = "Name of the kind Kubernetes cluster"
}
