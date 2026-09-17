variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "ami_id" {
  type        = string
  description = "AMI ID for the instance"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}
variable "subnet_id" {
  type        = string
  description = "Subnet to launch the instance in"
}
variable "security_group_id" {
  type        = string
  description = "Security group for the instance"
}
variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}
