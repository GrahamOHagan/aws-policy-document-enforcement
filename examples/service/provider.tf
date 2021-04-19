provider "aws" {
  region  = "eu-west-1"
  profile = "test-account-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
  profile = "test-account-1"
}
