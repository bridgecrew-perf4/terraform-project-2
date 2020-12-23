output "public_bucket_arn" {
  value = aws_s3_bucket.public_bucket.arn
}

output "public_bucket" {
  value = aws_s3_bucket.public_bucket
}