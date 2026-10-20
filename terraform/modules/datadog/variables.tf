variable "api_key" {
  type      = string
  sensitive = true
}

variable "cluster_name" {
  type = string
}

variable "database_metrics_endpoint" {
  type = string
}
variable "cache_metrics_endpoint" {
  type = string
}

variable "metrics_credentials_username" {
  type = string
}
variable "metrics_credentials_password" {
  type      = string
  sensitive = true
}
