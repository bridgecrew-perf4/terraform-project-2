variable "stack_name" {}

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
  name = "${title(var.stack_name)}CodeDeployPolicy"
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
        "autoscaling:RecordLifecycleActionHeartbeat"
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
  role   = aws_iam_role.keyed_app_deploy_role.name
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

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.stack_name
    }

    ec2_tag_filter {
      key   = "Terraform"
      type  = "KEY_AND_VALUE"
      value = true
    }
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "keyedin APP Deployment"
    trigger_target_arn = aws_sns_topic.deployment_sns.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}