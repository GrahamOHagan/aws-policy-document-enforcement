
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "BasePermissions"
    actions = [
      "s3:DeleteBucketPolicy",
      "iam:DeletePolicy",
      "iam:DeleteRolePolicy",
      "iam:DeleteUserPolicy",
      "iam:DeleteGroupPolicy",
      "iam:DeletePolicyVersion"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchLogGroups"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}
