#Amazon Certificate Manager
variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
  default     = "kojoawsterraform.com"
}

variable "san_domains" {
  description = "Subject alternative names for the certificate"
  type        = list(string)
  default     = ["*.kojoawsterraform.com"]
}

variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  type        = string
  default     = "Z017005815OW03C0E0OZA" # Replace with actual Route 53 Zone ID
}

variable "tags" {
  description = "Common tags for the cluster resources"
  type        = map(string)
  default     = {
    env       = "prod",
    terraform = "true"
  }
}