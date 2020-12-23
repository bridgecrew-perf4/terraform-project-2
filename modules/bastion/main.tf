variable "stack_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_hosts" {
  description = "CIDR blocks of trusted networks"
  default     = ["0.0.0.0/0"]
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "bastion" {
  name        = "Bastion host of keyedin.app"
  description = "Allow SSH access to bastion host and outbound internet access"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "${var.stack_name} Bastion"
    Terraform = true
  }
}

resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = [var.allowed_hosts]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "intranet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.vpc.cidr_block]
  security_group_id = aws_security_group.bastion.id
}

locals {
  public_key_filename  = "./ssh/key-keyedin-bastion.pub"
  private_key_filename = "./ssh/key-keyedin-bastion"
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated" {
  depends_on = [tls_private_key.default]
  key_name   = "key-${var.stack_name}-bastion"
  public_key = tls_private_key.default.public_key_openssh
}

resource "local_file" "public_key_openssh" {
  depends_on = [tls_private_key.default]
  content    = tls_private_key.default.public_key_openssh
  filename   = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  depends_on = [tls_private_key.default]
  content    = tls_private_key.default.private_key_pem
  filename   = local.private_key_filename
}

resource "null_resource" "chmod" {
  depends_on = [local_file.private_key_pem]

  provisioner "local-exec" {
    command = "chmod 400 ${local.private_key_filename}"
  }
}


resource "aws_instance" "server" {
  ami                         = local.ami
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.generated.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name      = "${var.stack_name} Bastion host"
    Terraform = true
  }
}

locals {
  instance_type = "t2.micro"
  ami           = "ami-08b993f76f42c3e2f"
}
