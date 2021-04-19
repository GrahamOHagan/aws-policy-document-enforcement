resource "aws_iam_policy" "test" {
  name = "test-iam-policy-enforcement"
  path = "/test/"
  description = "Testing iam policy condition enforcement"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "*"
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
