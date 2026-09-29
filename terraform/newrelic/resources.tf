# Account-level alerting for wayfinder ticket 008/010's Logs pillar decision:
# email on error-pattern log lines from any of the staging/prod services
# forwarded by modules/newrelic's Fluent Bit log shipper. Not tied to a
# specific environment's Kubernetes cluster, so this is its own stack --
# same shape as terraform/jenkins.

resource "newrelic_alert_policy" "error_logs" {
  name = "sports-app error logs"
}

resource "newrelic_notification_destination" "email" {
  name = "sports-app-alert-email"
  type = "EMAIL"

  property {
    key   = "email"
    value = var.alert_email
  }
}

resource "newrelic_notification_channel" "email" {
  name           = "sports-app-alert-email-channel"
  type           = "EMAIL"
  destination_id = newrelic_notification_destination.email.id
  product        = "IINT"

  property {
    key   = "subject"
    value = "sports-app error alert: {{ issueTitle }}"
  }
}

resource "newrelic_workflow" "error_logs" {
  name                  = "sports-app error logs workflow"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "filter-by-policy"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.error_logs.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.email.id
  }
}

# Best-effort keyword match over unstructured, multi-language stdout logs
# (see 008's Decisions section -- structured logging was explicitly deferred).
# Expect to tune these patterns once real log volume is flowing.
resource "newrelic_nrql_alert_condition" "error_logs" {
  policy_id                    = newrelic_alert_policy.error_logs.id
  type                         = "static"
  name                         = "Error-pattern log lines"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM Log WHERE message LIKE '%Exception%' OR message LIKE '%Error%' OR message LIKE '%Traceback%' OR message LIKE '%FATAL%'"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}
