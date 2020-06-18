terraform {
  required_providers {
    aws = ">= 2.7.0"
    random = ">= 2.2"
  }
}

data "aws_vpcs" "vpcs" {
  count = var.enabled ? 1 : 0
}

resource "random_string" "uuid" {
  count = var.enabled ? 1 : 0
  length = 5
  special = false
}

data "template_file" "trumpet" {
  template = file("${path.module}/templates/trumpet.json")
  vars = {
    HEC_TOKEN = var.hec_token
    ENDPOINT_URL = var.endpoint_url
    VPCFLOWLOGS = var.flow_log_loggroup
    CLOUDWATCHLOGS = var.cloud_watch_loggroup
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  count = var.enabled ? 1 : 0
  name = var.cloud_watch_loggroup
}

resource "aws_cloudformation_stack" "flowlogs" {
  count = (var.enable_flowlog && var.enabled) ? 1 : 0
  name = "flowlogs-${random_string.uuid[0].result}"
  parameters = merge(
    { "LogGroupName" = var.flow_log_loggroup },
    zipmap(
      tolist(slice(["VpcId", "VpcId2", "VpcId3", "VpcId4", "VpcId5"], 0,
        length(tolist(data.aws_vpcs.vpcs[0].ids)))),
      tolist(data.aws_vpcs.vpcs[0].ids)))
  template_body = file("${path.module}/templates/flowlogs.yaml")
  capabilities = [
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]
  disable_rollback = false
}

resource "aws_cloudformation_stack" "trumpet" {
  count = var.enabled ? 1 : 0
  name = "trumpet-${random_string.uuid[0].result}"
  template_body = data.template_file.trumpet.rendered
  capabilities = [
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]
  disable_rollback = false
  depends_on = [
    aws_cloudformation_stack.flowlogs,
    aws_cloudwatch_log_group.logs
  ]
}
