data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

module "networking" {
  source             = "../../modules/networking"
  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  allowed_ssh_cidr   = var.allowed_ssh_cidr
}

module "compute" {
  source            = "../../modules/compute"
  name_prefix       = var.name_prefix
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.networking.security_group_id
  key_name          = var.key_name
}

module "kubernetes" {
  source       = "../../modules/kubernetes"
  name_prefix  = var.name_prefix
  cluster_name = var.cluster_name
  config_path  = "${path.module}/kind-config.yaml"
}
