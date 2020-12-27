variable "stack_name" {}

variable "keyedin_lb_tg_name" {}

variable "keyedin_alb_id" {}

variable "keyedin_asg" {}

data "aws_region" "current" {}

resource "aws_iam_role" "keyed_app_deploy_role" {
  name = "${title(var.stack_name)}CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "keyedin_codedeploy_policy" {
  name   = "${title(var.stack_name)}CodeDeployPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:DeleteLifecycleHook",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLifecycleHooks",
        "autoscaling:PutLifecycleHook",
        "autoscaling:RecordLifecycleActionHeartbeat",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeInstanceHealth",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetTags",
        "tag:GetResources"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "keyedin_codedeploy_policy" {
  role       = aws_iam_role.keyed_app_deploy_role.name
  policy_arn = aws_iam_policy.keyedin_codedeploy_policy.arn
}

resource "aws_iam_role_policy_attachment" "keyedin_codedeploy_alb_policy" {
  role       = aws_iam_role.keyed_app_deploy_role.name
  policy_arn = aws_iam_policy.keyedin_codedeploy_policy.arn
}



resource "aws_codedeploy_app" "keyedin_app" {
  name             = var.stack_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_config" "keyedin_deployment_config" {
  deployment_config_name = "keyedin_app_config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }
}

resource "aws_sns_topic" "deployment_sns" {
  name = "${var.stack_name}-deployment-status"
}

resource "aws_codedeploy_deployment_group" "keyedin_deployment_group" {
  app_name               = aws_codedeploy_app.keyedin_app.name
  deployment_group_name  = var.stack_name
  service_role_arn       = aws_iam_role.keyed_app_deploy_role.arn
  deployment_config_name = aws_codedeploy_deployment_config.keyedin_deployment_config.id

  autoscaling_groups = [var.keyedin_asg]

  # ec2_tag_set {
  #   ec2_tag_filter {
  #     key   = "Name"
  #     type  = "KEY_AND_VALUE"
  #     value = var.stack_name
  #   }
  # }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "keyedin APP Deployment"
    trigger_target_arn = aws_sns_topic.deployment_sns.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = var.keyedin_lb_tg_name
    }
  }
}