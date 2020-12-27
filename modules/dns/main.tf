data "aws_lb" "stack_alb" {
  name = var.stack_alb_name
}


resource "aws_route53_zone" "main" {
  name    = var.stack_domain
  comment = "Domain for Keyedin.app API"

  tags = {
    Name      = var.stack_name
    Terraform = true
  }
}

# resource for creating www.keyedin.app A record with ALB alias
resource "aws_route53_record" "www_a_records" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.stack_domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.stack_alb.dns_name
    zone_id                = data.aws_lb.stack_alb.zone_id
    evaluate_target_health = true
  }
}

# pointing keyedin.app to ALB
resource "aws_route53_record" "root_a_records_to_alb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.stack_domain
  type    = "A"

  alias {
    name                   = data.aws_lb.stack_alb.dns_name
    zone_id                = data.aws_lb.stack_alb.zone_id
    evaluate_target_health = true
  }
}
