variable "stack_name" {
  type = string
}

locals {
  php_repo   = "${var.stack_name}/backend"
  nginx_repo = "${var.stack_name}/nginx"
}

resource "aws_ecr_repository" "backend" {
  name = local.php_repo

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "Name"      = var.stack_name
    "Terraform" = true
  }
}


resource "aws_ecr_repository" "nginx" {
  name = local.nginx_repo

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "Name"      = var.stack_name
    "Terraform" = true
  }
}