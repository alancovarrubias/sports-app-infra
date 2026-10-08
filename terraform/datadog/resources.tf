# Account-level alerting for wayfinder ticket 008/010's Logs pillar decision:
# email on error-pattern log lines from any of the staging/prod services
# forwarded by modules/datadog's Agent. Not tied to a specific environment's
# Kubernetes cluster, so this is its own stack -- same shape as
# terraform/jenkins.
#
# Datadog's monitor model needs no separate notification-channel/workflow
# resources (unlike the New Relic provider) -- an @-mention of the email
# address directly in the monitor's message routes the notification.

resource "datadog_monitor" "error_logs" {
  name    = "sports-app error logs"
  type    = "log alert"
  message = <<-EOT
    Error-pattern log lines detected in sports-app logs.
    @${var.alert_email}
  EOT

  # Best-effort keyword match over unstructured, multi-language stdout logs
  # (see 008's Decisions section -- structured logging was explicitly
  # deferred). Expect to tune these patterns once real log volume is flowing.
  query = <<-EOT
    logs("status:error OR message:*Exception* OR message:*Traceback* OR message:*FATAL*").index("*").rollup("count").last("5m") > 0
  EOT

  monitor_thresholds {
    critical = 0
  }

  notify_no_data      = false
  include_tags        = true
  require_full_window = false
}
