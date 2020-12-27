output "zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "description"
}

output "nameservers" {
  value = aws_route53_zone.main.name_servers
}


