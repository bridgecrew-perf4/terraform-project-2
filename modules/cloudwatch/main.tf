variable "stack_name" {
  type = string
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "keyedin_prod_logs" {
  name = "${var.stack_name}/prod/logs"

  tags = {
    Name        = var.stack_name
    Terraform   = true
    Environment = "prod"
  }
}