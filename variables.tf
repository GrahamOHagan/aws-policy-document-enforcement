variable "pattern_source" {
  description = "Source for the Cloudtrail event pattern (e.g. aws.s3)."
  type        = string
  default     = "aws.s3"
}

variable "pattern_event_source" {
  description = "Event Source for the Cloudtrail event pattern (e.g. s3.amazonaws.com)."
  type        = string
  default     = "s3.amazonaws.com"
}

variable "pattern_events" {
  description = "List of events for the Cloudtrail event pattern (e.g. PutBucketPolicy)."
  type        = list(string)
  default     = ["PutBucketPolicy"]
}

variable "pattern_excluded_role_arns" {
  description = "List of role arns for the Cloudtrail event pattern to exclude from the filter."
  type        = list(string)
  default     = []
}

variable "custom_lambda_name" {
  description = "Custom name for the lambda function."
  default     = ""
}

variable "condition" {
  description = "Required conditions to enforce on the policy."
  type        = map(string)
  default = {
    operator = "StringEquals"
    key      = "aws:PrincipalOrgID"
    value    = "o-yyyyyyyyyy"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}