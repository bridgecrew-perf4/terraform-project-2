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

variable "vpc_id" {
  type = string
}


locals {
  nb_azs = length(data.aws_availability_zones.available.names)
}


data "aws_availability_zones" "available" {}

# Load balancers

resource "aws_security_group" "loadbalancer" {
  name        = "loadbalancer"
  description = "Keyedin ALB Load balancer SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.stack_name} Loadbalancer SG"
  }
}

resource "aws_lb_target_group" "keyedin_lb_tg" {
  name     = "${var.stack_name}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 3
    port                = 80
    path                = "/"
    interval            = 60
  }

  tags = {
    Name = "${var.stack_name} LB TG"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.keyedin_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keyedin_lb_tg.arn
  }
}


resource "aws_lb_target_group_attachment" "keyedin_lb_attachment" {
  count            = length(var.ec2_instance_ids)
  target_group_arn = aws_lb_target_group.keyedin_lb_tg.arn
  target_id        = var.ec2_instance_ids[count.index]
}

resource "aws_lb" "keyedin_lb" {
  name               = "${var.stack_name}-elb"
  load_balancer_type = "application"
  # availability_zones = data.aws_availability_zones.available.names
  subnets  = var.subnet_ids
  internal = false

  security_groups = [aws_security_group.loadbalancer.id]

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}

# auto-scaling
# data "aws_ami" "azm_linux" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["packer-keyedin-*"]
#   }

#   filter {
#     name   = "tag:Name"
#     values = ["Packer-Keyedin-AMI"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["079893911216"] # Canonical
# }

# resource "aws_launch_template" "webserver" {
#   name_prefix            = "webserver-"
#   image_id               = data.aws_ami.azm_linux.image_id
#   instance_type          = "t2.small"
#   key_name               = aws_key_pair.livestyled.key_name
#   vpc_security_group_ids = [aws_security_group.webserver.id]

#   tags = {
#     "Environment" = var.environment_tag
#   }
# }

# resource "aws_autoscaling_group" "webserver" {
#   max_size            = 2
#   min_size            = 2
#   vpc_zone_identifier = data.terraform_remote_state.networking.outputs.private_subnet_ids


#   launch_template {
#     id      = aws_launch_template.webserver.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Environment"
#     value               = var.environment_tag
#     propagate_at_launch = true
#   }
# }