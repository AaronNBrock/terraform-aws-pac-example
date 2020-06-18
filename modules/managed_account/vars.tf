variable "role_arn" {
  description = "The Role to assume with permissions in the account."
  type        = string
}

variable "enable_flowlog" {
  default = true
  type    = bool
}

variable "enabled" {
  default = true
  type    = bool
}

variable "region" {
  default = "us-east-1"
  type    = string
}

variable "endpoint_url" {
  type        = string
  description = "The URL endpoint for the HEC."
  default     = "https://splunk.jbennettconsulting.com:443"
}

variable "hec_token" {
  type        = string
  description = "The HEC token to use."
  default     = "beda0b1f-d761-4ea9-a15a-86ec16f119fd"
}

