output "backend_repo_arn" {
  value = aws_ecr_repository.backend.arn
}

output "backend_repo_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "nginx_repo_arn" {
  value = aws_ecr_repository.nginx.arn
}

output "nginx_repo_url" {
  value = aws_ecr_repository.nginx.repository_url
}