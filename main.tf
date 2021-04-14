# Eventbridge pattern rule - When a policy is created
resource "aws_cloudwatch_event_rule" "this" {
  name          = "policy-document-event"
  description   = "Trigger policy enforcement lambda."
  event_pattern = length(var.pattern_excluded_role_arns) > 0 ? local.event_pattern_excluded_roles : local.event_pattern

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_event_trigger" {
  statement_id  = "AllowExecutionFromCWEvent"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.this.arn
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

# Lambda Function
resource "aws_lambda_function" "this" {
  filename      = local.zip_location
  function_name = local.lambda_name
  role          = aws_iam_role.this.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.7"
  timeout = 300

  environment {
    variables = {
      OPERATOR = var.condition.operator
      KEY      = var.condition.key
      VALUE    = var.condition.value
    }
  }

  tags = var.tags
}


# Lambda Role
resource "aws_iam_role" "this" {
  name = "${local.lambda_name}-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  inline_policy {
    name = "lambda-policy"

    policy = data.aws_iam_policy_document.lambda_policy.json
  }

  tags = var.tags
}
