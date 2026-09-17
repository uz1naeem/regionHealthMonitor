variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
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
  description = "CIDR permitted to reach SSH and the app port"
}
