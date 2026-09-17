resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip git curl
  USERDATA

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "${var.name_prefix}-app" }
}
