# Without this, every log from these three services shows status:info
# regardless of actual severity -- confirmed empirically: a real FATAL-level
# Rails exception still showed status:info in Datadog, because Datadog has
# no built-in parser for Ruby's default Logger::Formatter output
# ("I, [timestamp #pid]  INFO -- : message" / "F, [...] FATAL -- : ..."). This
# grok-parses that severity word out and remaps it to Datadog's official
# status facet. Scoped to auth/football/sidekiq only -- crawler (Python) and
# server (Node) have entirely different log shapes this pattern won't match.
#
# Datadog's status remapper matches by first letter, case-insensitive, not
# full words -- so FATAL (starts with "f") maps to its highest severity,
# "emergency", not "error". The monitor below was updated to match on both.
resource "datadog_logs_custom_pipeline" "ruby_severity" {
  name       = "sports-app Ruby log severity"
  is_enabled = true

  filter {
    query = "service:auth OR service:football OR service:sidekiq"
  }

  processor {
    grok_parser {
      name       = "Extract Ruby Logger severity"
      source     = "message"
      is_enabled = true

      grok {
        match_rules   = <<-EOT
          ruby_logger %%{word:letter}, \[%%{notSpace:ruby_ts} #%%{number:pid}\]\s+%%{word:severity}\s+--\s+:
        EOT
        support_rules = ""
      }
    }
  }

  processor {
    status_remapper {
      name       = "Remap status from parsed Ruby severity"
      is_enabled = true
      sources    = ["severity"]
    }
  }
}

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

  # Scoped to our 6 app services explicitly -- an unscoped status:error
  # matched system noise (DOKS's own konnectivity-agent logs its routine
  # "write to remote"/"received DATA" chatter as status:error despite the
  # message itself being klog-INFO-prefixed) and, surprisingly, our own
  # `server`: Node's ExperimentalWarning and npm update notices on stdout
  # also come through as status:error with no pipeline to correct them.
  # Confirmed by inspecting real ingested events, not assumed.
  #
  # status:emergency/status:error is further scoped to only
  # auth/football/sidekiq -- the three services datadog_logs_custom_pipeline
  # .ruby_severity above actually makes that facet meaningful for (FATAL maps
  # to "emergency", Datadog's highest severity, not "error" -- see that
  # resource's comment for why). server/crawler have no such pipeline, so for
  # them this monitor still relies on best-effort keyword matching over
  # unstructured logs (structured logging there was explicitly deferred --
  # see 008's Decisions section) rather than status, which would just be
  # more of the same false-positive noise for those two.
  query = <<-EOT
    logs("((status:emergency OR status:error) service:(auth OR football OR sidekiq)) OR ((message:*Exception* OR message:*Traceback* OR message:*FATAL*) service:(auth OR football OR sidekiq OR server OR client OR crawler))").index("*").rollup("count").last("5m") > 0
  EOT

  monitor_thresholds {
    critical = 0
  }

  notify_no_data      = false
  include_tags        = true
  require_full_window = false
}
