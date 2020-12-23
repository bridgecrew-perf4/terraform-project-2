variable "stack_name" {
  type = string
}

variable "amz_ami" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ec2_sg" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}


resource "aws_launch_template" "webservers" {
  name_prefix            = "${var.stack_name}-"
  image_id               = var.amz_ami
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [var.ec2_sg]

  tags = {
    tags = {
      Name      = var.stack_name
      Terraform = true
    }
  }
}

resource "aws_autoscaling_group" "webserver" {
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = data.terraform_remote_state.networking.outputs.private_subnet_ids


  launch_template {
    id      = aws_launch_template.webserver.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = var.environment_tag
    propagate_at_launch = true
  }
}