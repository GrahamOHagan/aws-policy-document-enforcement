# Construct event pattern for the EventBridge rule
locals {
  event_pattern = jsonencode({
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "source" : [
      var.pattern_source
    ],
    "detail" : {
      "eventName" : var.pattern_events,
      "eventSource" : [
        var.pattern_event_source
      ]
    }
  })

  event_pattern_excluded_roles = jsonencode({
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "source" : [
      var.pattern_source
    ],
    "detail" : {
      "eventName" : var.pattern_events,
      "eventSource" : [
        var.pattern_event_source
      ],
      "userIdentity" : {
        "sessionContext" : {
          "sessionIssuer" : {
            "arn" : [{ "anything-but" : var.pattern_excluded_role_arns }]
          }
        }
      }
    }
  })
}

# Lambda deployment
locals {
  lambda_name = var.custom_lambda_name != "" ? var.custom_lambda_name : "policy-document-enforcement"

  source_files = fileset("${path.module}/function", "**")
  temp_path    = "temp_${random_string.random.result}"
  output_path  = "output_${random_string.random.result}"
  zip_location = "${path.module}/${local.output_path}/${local.lambda_name}.zip"
}

resource "random_string" "random" {
  length  = 8
  special = false
}

# Bundle relevant files into a temp folder
resource "local_file" "temp_dir" {
  for_each = local.source_files
  filename = "${path.module}/${local.temp_path}/${each.key}"
  content  = file("${path.module}/function/${each.key}")

  provisioner "local-exec" {
    command = "pip install -r ${path.module}/${local.temp_path}/requirements.txt -t ${path.module}/${local.temp_path}"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/${local.temp_path}"
  output_path = local.zip_location

  depends_on = [
    local_file.temp_dir
  ]
}
