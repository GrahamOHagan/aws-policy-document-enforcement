## aws-policy-document-enforcement

This module deploys a service that monitors and deletes any AWS policy documents that does not have a matching condition.

The service is a lambda that is invoked by EventBridge rules, the pattern is determined by variables, for example:

```
module "example" {
  source = "../../"
  pattern_source = "aws.s3"
  pattern_event_source = "s3.amazonaws.com"
  pattern_events = ["PutBucketPolicy"]

  ...
}
```
which will produce:
```
{
    "source": [
        "aws.s3"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
            "s3.amazonaws.com"
        ],
        "eventName": [
            "PutBucketPolicy"
        ]
    }
}
```

The lambda will be invoked, and delete the policy if it does not match a certain condition, the conidtion is determined by variables, for example:
```
module "example" {
  ...
  
  condition = {
    operator = "StringEquals"
    key      = "aws:PrincipalOrgID"
    value    = "o-yyyyyyyyyy"
  }
  
  ...
}
```
which will delete the rule if any statement of the policy does not have a condition that checks if the principal is of the above AWS Organization Id.

| Variable                   | Description                                   | Default                       |
| -------------------------- |:---------------------------------------------:| -----------------------------:|
| pattern_source             | Source for the CloudTrail Event pattern       | `"aws.s3"`                    |
| pattern_event_source       | Event source for the CloudTrail Event pattern | `"s3.amazonaws.com"`          |
| pattern_events             | Event names for the CloudTrail Event pattern  | `["PutBucketPolicy"]`.        |
| pattern_excluded_role_arns | List of excluded roles                        | `NA`                          |
| condition                  | Condition to enforce.                         | {operator = "StringEquals"<br>key = "aws:PrincipalOrgID"<br>value = "o-yyyyyyyyyy"} |
| custom_lambda_name         | Custom name for the lambda                    | `policy-document-enforcement` |
| tags                       | Tags for the lambda and dependant resources   | `NA`                          |
