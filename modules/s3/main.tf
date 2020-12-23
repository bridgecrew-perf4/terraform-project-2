variable "stack_name" {
  type = string
}


resource "aws_s3_bucket_policy" "public_bucket_policy" {
  bucket = aws_s3_bucket.public_bucket.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Resource": [
        "${aws_s3_bucket.public_bucket.arn}/*"
      ],
      "Condition": {
         "IpAddress": {"aws:SourceIp": "8.8.8.8/32"}
      }
    }
  ]
}
EOF
}


resource "aws_s3_bucket" "public_bucket" {
  bucket = "${var.stack_name}-public"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  tags = {
    Name = var.stack_name
  }
}