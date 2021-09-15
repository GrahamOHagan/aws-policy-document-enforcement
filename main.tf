# Eventbridge pattern rule - When a policy is created
resource "aws_cloudwatch_event_rule" "this" {
  name          = "policy-document-event"
  description   = "Trigger policy enforcement lambda."
  event_pattern = length(var.pattern_excluded_role_names) > 0 ? local.event_pattern_excluded_roles : local.event_pattern

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

# If source is iam and region is not N Virginia, then need to create rule from us-east-1 to current region.
resource "aws_cloudwatch_event_rule" "n_virginia" {
  count         = var.pattern_source == "aws.iam" && data.aws_region.current.name != "us-east-1" ? 1 : 0
  name          = "policy-document-event"
  description   = "Trigger policy enforcement lambda."
  event_pattern = length(var.pattern_excluded_role_names) > 0 ? local.event_pattern_excluded_roles : local.event_pattern

  tags = var.tags

  provider = aws.use1
}

resource "aws_cloudwatch_event_target" "n_virginia" {
  count     = var.pattern_source == "aws.iam" && data.aws_region.current.name != "us-east-1" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.n_virginia[0].name
  role_arn  = aws_iam_role.event[0].arn
  target_id = "CrossAccount"
  arn       = "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/default"

  provider = aws.use1
}

resource "aws_iam_role" "event" {
  count = var.pattern_source == "aws.iam" && data.aws_region.current.name != "us-east-1" ? 1 : 0
  name  = "${local.lambda_name}-cross-account-role"

  assume_role_policy = data.aws_iam_policy_document.event_trust.json

  inline_policy {
    name   = "event-policy"
    policy = data.aws_iam_policy_document.event_policy.json
  }

  tags = var.tags
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

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.tags
}

# Lambda Role
resource "aws_iam_role" "this" {
  name = "${local.lambda_name}-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  inline_policy {
    name   = "lambda-policy"
    policy = data.aws_iam_policy_document.lambda_policy.json
  }

  tags = var.tags
}
