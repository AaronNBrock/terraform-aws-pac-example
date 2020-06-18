variable "enable_flowlog" {
  type = bool
  default = true
  description = "Enable flowlogging."
}

variable "enabled" {
  type = bool
  default = true
  description = "Enable everything."
}

variable "flow_log_loggroup" {
  type = string
  default = "/splunk/vpc/flowlogs"
  description = "The cloudwatch log group to push flow logs to."
}

variable "cloud_watch_loggroup" {
  type = string
  default = "/splunk/cloudwatch/logs"
  description = "The cloudwatch log group to push logs to."
}

variable "endpoint_url" {
  type = string
  description = "The URL endpoint for the HEC."
}

variable "hec_token" {
  type = string
  description = "The HEC token to use."
}
