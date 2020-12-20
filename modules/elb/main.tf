variable "stack_name" {
    type = string
}

variable "subnet_ids" {
    type = list(string)
}

variable "security_groups" {
    type = list(string)
}

variable "ec2_instance_ids" {
    type = list(string)
}


locals {
  nb_azs = length(data.aws_availability_zones.available.names)
}


data "aws_availability_zones" "available" {}

# Load balancers

resource "aws_elb" "keyedin_lb" {
    name = "${var.stack_name}-elb"
    # availability_zones = data.aws_availability_zones.available.names
    subnets = var.subnet_ids

    security_groups = var.security_groups

    listener {
        instance_port = 80
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 60
  }

  instances = var.ec2_instance_ids

  tags = {
    Name = var.stack_name
    Terraform = true
  }
}

