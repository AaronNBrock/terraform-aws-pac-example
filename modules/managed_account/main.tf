#
# Provider
#
provider "aws" {
  alias   = "managed_account"
  version = "~> 2"
  region  = var.region
  assume_role {
    role_arn = var.role_arn
  }
}

module "aws_splunk_integration" {
  providers = {
    aws = aws.managed_account
  }
  source         = "../aws-splunk-integration"
  endpoint_url   = var.endpoint_url
  hec_token      = var.hec_token
  enable_flowlog = var.enable_flowlog
  enabled        = var.enabled
}

module "config_rules" {
  providers = {
    aws = aws.managed_account
  }
  source          = "../config_rules"
  name_prefix     = "aws-sentinel-"
  create_recorder = false
  enabled         = var.enabled
}
