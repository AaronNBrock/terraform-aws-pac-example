variable "bucket_names" {
  description = "The name of the ELB Access logs bucket."
  type = list
}

  #List: https://docs.aws.amazon.com/elasticloadbalancing/latest/application//load-balancer-access-logs.html \
variable "elb_account_id" {
  #us-east-1 AWS ELB account id
  default = "127311923021"
  description = "A list of AWS ELB account ids can be found on line. Please choose the one for your region."
}

variable "enabled" {
  type = bool
  default = true
}

variable "enable_sqs" {
  type = bool
  default = false
}
