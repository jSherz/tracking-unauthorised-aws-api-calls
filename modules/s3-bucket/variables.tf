variable "name" {
  type        = string
  description = "Bucket name."
}

variable "versioning" {
  type        = bool
  default     = true
  description = "Enable bucket versioning?"
}

variable "policy" {
  type        = string
  default     = null
  description = "Bucket IAM policy."
}

variable "apply_policy" {
  type        = bool
  default     = false
  description = "Set the bucket's policy?"
}

variable "enable_log_delivery" {
  type        = bool
  description = "Allow AWS log delivery, e.g. for CloudFront access logs."
  default     = false
}
