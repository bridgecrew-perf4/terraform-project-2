output "codedeploy_app_name" {
  value = aws_codedeploy_app.keyedin_app
}

output "codedeploy_sns_topic" {
  value = aws_sns_topic.deployment_sns.name
}

output "codedeploy_deployment_group" {
  value = aws_codedeploy_deployment_group.keyedin_deployment_group.id
}