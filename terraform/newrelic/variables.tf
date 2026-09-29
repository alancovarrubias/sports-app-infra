variable "newrelic_account_id" {
  type = string
}

variable "newrelic_api_key" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type = string
}
