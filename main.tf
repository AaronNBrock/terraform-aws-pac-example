provider "aws" {
  version = "~> 2"
  region  = "us-east-1"
}

module "example_account" {
  source   = "./modules/managed_account"
  role_arn = "<Role ARN>"
}

