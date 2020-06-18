# Get the access to the effective Account ID in which Terraform is working.
data "aws_caller_identity" "current" {
  count = ( var.create_recorder && var.enabled ) ? 1 : 0
}

resource "random_string" "bucket_uniqueifyer" {
  length  = 6
  special = false
  number  = false
  upper   = false
}

locals {
  bucket_name   = "${var.name_prefix}config-logs-bucket-${random_string.bucket_uniqueifyer.result}${var.name_suffix}"
  s3_key_prefix = "${var.name_prefix}config-recorder-logs${var.name_suffix}"
}


resource "aws_config_configuration_recorder_status" "main" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name       = aws_config_configuration_recorder.main.0.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main.0]
}

resource "aws_config_delivery_channel" "main" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name           = "${var.name_prefix}delivery-channel${var.name_suffix}"
  s3_bucket_name = aws_s3_bucket.config.0.bucket
  s3_key_prefix  = local.s3_key_prefix
  depends_on     = [aws_config_configuration_recorder.main.0]
}

#
# AWS Config Recorder
#
resource "aws_config_configuration_recorder" "main" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name     = "${var.name_prefix}config-recorder${var.name_suffix}"
  role_arn = aws_iam_role.recorder.0.arn

  recording_group {
    all_supported = true
  }
}

#
# Bucket
#
resource "aws_s3_bucket" "config" { # TODO: Maybe configure a common bucket accross all accounts?
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  bucket = local.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


#
# IAM Role
#



# Allow IAM policy to assume the role for AWS Config
data "aws_iam_policy_document" "aws-config-role-policy" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    effect = "Allow"
  }
}

#
# IAM
#

resource "aws_iam_role" "recorder" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name               = "${var.name_prefix}config-recorder${var.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.aws-config-role-policy.0.json
}

resource "aws_iam_policy_attachment" "managed-policy" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name       = "${var.name_prefix}config-recorder-managed-policy${var.name_suffix}"
  roles      = [aws_iam_role.recorder.0.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_policy" "aws-config-policy" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name   = "${var.name_prefix}config-recorder-policy${var.name_suffix}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "AWSConfigBucketPermissionsCheck",
        "Effect": "Allow",
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::${local.bucket_name}"
    },
    {
        "Sid": "AWSConfigBucketExistenceCheck",
        "Effect": "Allow",
        "Action": "s3:ListBucket",
        "Resource": "arn:aws:s3:::${local.bucket_name}"
    },
    {
        "Sid": "AWSConfigBucketDelivery",
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${local.bucket_name}/${local.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current[0].account_id}/Config/*",
        "Condition": {
          "StringLike": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
    },
    {
      "Action": "config:Put*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "aws-config-policy" {
  count      = ( var.create_recorder && var.enabled ) ? 1 : 0
  name       = "${var.name_prefix}config-recorder-policy${var.name_suffix}"
  roles      = [aws_iam_role.recorder.0.name]
  policy_arn = aws_iam_policy.aws-config-policy.0.arn
}