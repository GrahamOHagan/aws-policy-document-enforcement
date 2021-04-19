terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
      # configuration_aliases = [ "use1" ] # TF0.15
    }
  }
}

# provider "aws" {
#   alias = "use1"
# }
