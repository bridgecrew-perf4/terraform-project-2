variable "stack_name" {
  type = string
}

resource "aws_s3_bucket" "public_bucket" {
  bucket_prefix = "${var.stack_name}-public"
  acl           = "public-read"

  tags = {
    Name = var.stack_name
    Terraform = true
  }
}

resource "aws_s3_bucket" "private_bucket" {
  bucket_prefix = "${replace(var.stack_name, "/[^a-z0-9.]+/", "-")}-private"
  acl = "private"

  tags = {
    Name = var.stack_name
    Terraform = true
  }
}