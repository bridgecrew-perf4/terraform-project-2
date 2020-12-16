output "public_bucket_arn" {
  value = aws_s3_bucket.public_bucket.arn
}

output "private_bucket_arn" {
  value = aws_s3_bucket.private_bucket.arn
}

output "public_bucket" {
  value = aws_s3_bucket.public_bucket
}

output "private_bucket" {
  value = aws_s3_bucket.private_bucket
}