output "elb_arn" {
  value = aws_lb.keyedin_lb.arn
}

output "elb_id" {
  value = aws_lb.keyedin_lb.id
}

output "elb_name" {
  value = aws_lb.keyedin_lb.name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.keyedin_lb_tg.arn
}