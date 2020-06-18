provider "aws" {
  version = "~> 2"
  region  = "us-east-1"
}

#
# Variables
#
variable "ssh_key_name" {
  description = "The name of an ssh key to deploy to the servers."
  type        = string
}

#
# Jenkins Server
#

# Role
data "aws_iam_policy_document" "jenkins_auth_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "jenkins-role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.jenkins_auth_policy.json
}

# Assume Role Policy
data "aws_iam_policy_document" "jenkins_assume_roles_policy" {
  statement {
    sid = "1"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::*:role/terraform-aws-pac-example"
    ]

  }
}

resource "aws_iam_role_policy" "jenkins_assume_roles" {
  name   = "jenkins-assume-roles"
  role   = aws_iam_role.jenkins.id
  policy = data.aws_iam_policy_document.jenkins_assume_roles_policy.json
}

# Access Backend Policy
data "aws_iam_policy_document" "jenkins_access_backend_policy" {

  statement {
    sid = "1"

    actions = [
      "s3:*",
      "dynamodb:*"
    ]

    resources = [
      "arn:aws:s3:::terraform-aws-pac-example",
      "arn:aws:s3:::terraform-aws-pac-example/*",
      "arn:aws:dynamodb:*:*:table/terraform-aws-pac-example"
    ]

  }
}

resource "aws_iam_role_policy" "jenkins_access_backend" {
  name   = "jenkins-access-backend"
  role   = aws_iam_role.jenkins.id
  policy = data.aws_iam_policy_document.jenkins_access_backend_policy.json
}

# Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# Instance
module "jenkins" {
  source               = "github.com/AaronNBrock/terraform-aws-jenkins.git?ref=v0.1.3"
  ssh_key_name         = var.ssh_key_name
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name
}



#
# Terraform State Backend
#
module "terraform-aws-splunk-enabler" {
  source       = "github.com/AaronNBrock/s3-backend-resources.git?ref=v0.1.0"
  backend_name = "terraform-aws-pac-example"
}

#
# Outputs
#
output "next_steps" {
  value = module.jenkins.next_steps
}


