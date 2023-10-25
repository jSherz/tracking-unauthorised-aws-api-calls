variable "cloudtrail_bucket" {
  type    = string
  default = "jsj-cloudtrail"
}

variable "email_source" {
  type        = string
  description = "E-mail address to send reports from. Must be setup with a verified identity in SES. e.g.: Joe Bloggs <joe@example.com>"
}

variable "email_destination" {
  type        = string
  description = "E-mail address to send reports to. I'd suggest you use a distribution list or group for your ops team."
}

variable "enabled_regions" {
  type        = list(string)
  description = "Regions you want to search CloudTrail data for."
}
