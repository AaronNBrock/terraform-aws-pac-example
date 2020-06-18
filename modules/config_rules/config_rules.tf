#
# S3 Versioning Enabled
#

#
# S3 Tagging Enabled
#
resource "aws_config_config_rule" "required-tags" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name_prefix}required-tags${var.name_suffix}"
  description = "Verify that tags exist on S3 Buckets."

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "Owner"

  })


  scope {
    compliance_resource_types = [
      "AWS::S3::Bucket",
      "AWS::IAM::Role"
    ]
  }

  depends_on = [aws_config_configuration_recorder.main]
}
