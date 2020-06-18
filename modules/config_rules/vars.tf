

variable "name_prefix" {
  description = "Prefix to attach to all named resources."
  default     = ""
}

variable "name_suffix" {
  description = "Suffix to attach to all named resources."
  default     = ""
}

variable "create_recorder" {
  description = "Whether or not to create a recorder (don't create one if one already exists!)"
  type        = bool
  default     = true
}

variable "enabled" {
  type    = bool
  default = true
}
