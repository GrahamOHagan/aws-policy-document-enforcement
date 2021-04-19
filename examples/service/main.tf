module "service" {
  source = "../../"

  pattern_source = "aws.iam"
  pattern_event_source = "iam.amazonaws.com"
  pattern_events = ["CreatePolicy", "CreatePolicyVersion"]


  tags = {
    Name        = "TestingPolicyEnforcementService"
    Role        = "TestingPolicyEnforcementService"
    Environment = "Development"
  }

  providers = {
    aws.def = aws
    aws.use1 = aws.use1
  }
}
