terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">= 2"
  }
}

#
# Remediation
#
resource "aws_cloudformation_stack" "bucket_versioning_remediation" {
  count      = var.enabled ? 1 : 0
  name       = "${var.name_prefix}bucket-versioning-remediation${var.name_suffix}"
  depends_on = [var.config_rule, aws_iam_role.bucket_versioning]

  parameters = {
    Automatic            = true
    ConfigRuleName       = var.config_rule.0.name
    AutomationAssumeRole = aws_iam_role.bucket_versioning.0.arn
    VersioningState      = var.versioning_enabled ? "Enabled" : "Disabled"
  }

  template_body = file("${path.module}/remediation.json")
}

#
# IAM
#
data "aws_iam_policy_document" "bucket_versioning_trust" {
  count = var.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "bucket_versioning_attached" {
  count = var.enabled ? 1 : 0
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "s3:*",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    sid    = "2"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.bucket_versioning.0.arn
    ]
  }
  statement {
    sid    = "3"
    effect = "Allow"
    actions = [
      "ssm:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "4"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:Automation*"
    ]
  }
}

resource "aws_iam_policy" "bucket_versioning_policy" {
  count = var.enabled ? 1 : 0

  name        = "${var.name_prefix}bucket-versioning-policy${var.name_suffix}"
  description = "A policy for allowing terraform"
  policy      = data.aws_iam_policy_document.bucket_versioning_attached.0.json
}

resource "aws_iam_role_policy_attachment" "bucket_versioning_attach" {
  count = var.enabled ? 1 : 0

  role       = aws_iam_role.bucket_versioning.0.name
  policy_arn = aws_iam_policy.bucket_versioning_policy.0.arn
}

resource "aws_iam_role" "bucket_versioning" {
  count              = var.enabled ? 1 : 0
  name               = "${var.name_prefix}bucket-versioning-role${var.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.bucket_versioning_trust.0.json
}
