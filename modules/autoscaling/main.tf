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

variable "iam_instance_profile" {
  type = string
}

variable "loadbalancer_arn" {
  type = string
}

variable "alb_target_group_arn" {
  type = string
}


data "aws_lb" "keyedin_alb" {
  arn = var.loadbalancer_arn
}


data "aws_lb_target_group" "keyedin_lb_tg" {
  arn = var.alb_target_group_arn
}

data "aws_iam_role" "sns_role" {
  name = "SnsPublishRole"
}

locals {
  sns_subscription_email_address_list = ["keyedinapp@gmail.com"]
  sns_subscription_protocol = "email"
}

data "template_file" "aws_cf_sns_stack" {
   template = file("${path.module}/templates/cf_aws_sns_email_stack.json.tpl")
   vars = {
     sns_topic_name        = "asg-event-update"
     sns_display_name      = "Autoscaling Group Event Update Notification"
     sns_subscription_list = join(",", formatlist("{\"Endpoint\": \"%s\",\"Protocol\": \"%s\"}",
     local.sns_subscription_email_address_list,
     local.sns_subscription_protocol))
   }
 }

 resource "aws_cloudformation_stack" "tf_sns_cloudformation" {
  name = "snsStack"
  template_body = data.template_file.aws_cf_sns_stack.rendered

  tags = {
    Name = var.stack_name
    Terrraform = true
  }
}

data "aws_sns_topic" "asg_scaling_notification" {
  name = "asg-event-update"
}


resource "aws_launch_template" "webservers" {
  image_id               = var.amz_ami
  instance_type          = "t2.medium"
  key_name               = var.key_name

  instance_initiated_shutdown_behavior = "terminate"

  user_data = filebase64("${path.module}/../ec2/user_data.sh")

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [var.ec2_sg]
  }

  tags = {
    Name      = var.stack_name
    ASG       = true
    Terraform = true
  }
}

resource "aws_autoscaling_group" "webserver" {
  name                = "${var.stack_name}-ASG"
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [var.alb_target_group_arn]

  health_check_type = "ELB"

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.webservers.id
        version            = "$Latest"
      }

      override {
        instance_type = "t2.medium"
      }

      override {
        instance_type = "t3.medium"
      }

      override {
        instance_type = "t3.large"
      }

    }
  }

  tags = concat([
    {
      "key"                 = "Name"
      "value"               = var.stack_name
      "propagate_at_launch" = true
    },
    {
      "key"                 = "ASG"
      "value"               = true
      "propagate_at_launch" = true
    },
    {
      "key"               = "Terraform"
      "value"             = true
      propagate_at_launch = true
    }
  ])
}

resource "aws_autoscaling_policy" "scaling_webservers_by_change" {
  name            = "${var.stack_name}-autoscaling-policy"
  adjustment_type = "ChangeInCapacity"
  policy_type     = "TargetTrackingScaling"

  autoscaling_group_name = aws_autoscaling_group.webserver.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${data.aws_lb.keyedin_alb.arn_suffix}/${data.aws_lb_target_group.keyedin_lb_tg.arn_suffix}"
    }

    target_value = 1000
  }
}

resource "aws_autoscaling_lifecycle_hook" "asg_notification_hooks_instance_terminate" {
  name = "asg-hook-instance-terminating"
  autoscaling_group_name = aws_autoscaling_group.webserver.name
  default_result = "CONTINUE"
  heartbeat_timeout = 2000
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

  notification_target_arn = data.aws_sns_topic.asg_scaling_notification.arn
  role_arn = data.aws_iam_role.sns_role.arn
}

resource "aws_autoscaling_lifecycle_hook" "asg_notification_hooks_instance_launching" {
  name = "asg-hook-instance-launching"
  autoscaling_group_name = aws_autoscaling_group.webserver.name
  default_result = "CONTINUE"
  heartbeat_timeout = 2000
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

  notification_target_arn = data.aws_sns_topic.asg_scaling_notification.arn
  role_arn = data.aws_iam_role.sns_role.arn
}


