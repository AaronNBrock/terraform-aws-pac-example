terraform {
  backend "s3" {
    bucket         = "terraform-aws-pac-example"
    key            = "default/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-aws-pac-example"
    encrypt        = true
  }
}
