resource "aws_s3_bucket" "test" {
  bucket = "test-bucket-policy-enforcement"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  tags = {
    Name        = "TestingPolicyEnforcementService"
    Role        = "TestingPolicyEnforcementService"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_policy" "test" {
  bucket = aws_s3_bucket.test.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "${aws_s3_bucket.test.arn}",
        "${aws_s3_bucket.test.arn}/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-yyyyyyyyyy"
        }
      }
    }
  ]
}
EOF
}
