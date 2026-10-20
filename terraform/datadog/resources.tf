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

  # Pipeline filters match against source, not service -- confirmed
  # empirically: with a service:-based filter, real logs from these pods
  # still carried the datadog.pipelines:false tag (Datadog's own documented
  # signal for "no pipeline matched this log"), meaning the filter wasn't
  # matching at all, not that the grok pattern failed to parse.
  filter {
    query = "source:auth OR source:football OR source:sidekiq"
  }

  processor {
    grok_parser {
      name       = "Extract Ruby Logger severity"
      source     = "message"
      is_enabled = true

      # Datadog's grok parser requires matching the ENTIRE message, not a
      # leading substring -- confirmed directly in Datadog's live grok
      # tester: a rule covering only "F, [...] FATAL -- :" reported NO MATCH
      # despite being correct as far as it went, and only matched once a
      # trailing %{data:error_message} was added to consume the rest of the
      # line (the actual exception/backtrace). `data` explicitly handles
      # newlines, so this also covers full multi-line Rails backtraces.
      # Also: `number` doesn't match a bare integer like a pid ("9") --
      # Datadog's own AI rule-generator used `integer` for the same field.
      grok {
        match_rules   = <<-EOT
          ruby_logger %%{word:letter}, \[%%{notSpace:ruby_ts} #%%{integer:pid}\] %%{word:severity} -- : %%{data:error_message}
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

# Account-level overview dashboard: Kubernetes cluster health (via the
# Agent's built-in metrics) plus the DO-managed Postgres/Valkey host metrics
# enabled in modules/datadog. DO's metrics_endpoints exporter only reports
# host-level stats (CPU/mem/disk/network/load) for the DB's underlying
# machine, not engine-internal stats (connections, cache hit ratio,
# replication lag) -- that would need the native postgres/redis Agent
# checks with DB credentials instead, a separate decision.
resource "datadog_dashboard" "overview" {
  title       = "sports-app infra overview"
  description = "Kubernetes cluster health plus DO-managed Postgres/Valkey host metrics"
  layout_type = "ordered"

  template_variable {
    name     = "cluster_name"
    prefix   = "cluster_name"
    defaults = ["*"]
  }

  widget {
    group_definition {
      title       = "Kubernetes Cluster"
      layout_type = "ordered"

      widget {
        timeseries_definition {
          title       = "CPU Usage"
          show_legend = false
          request {
            q            = "avg:kubernetes.cpu.usage.total{$cluster_name}"
            display_type = "line"
            style {
              palette = "blue"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Memory Usage %"
          show_legend = false
          request {
            q            = "avg:kubernetes.memory.usage_pct{$cluster_name}"
            display_type = "line"
            style {
              palette = "orange"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Node Count"
          show_legend = false
          request {
            q            = "avg:kubernetes_state.node.count{$cluster_name}"
            display_type = "line"
            style {
              palette = "grey"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Container Restarts"
          show_legend = false
          request {
            q            = "sum:kubernetes_state.container.restarts{$cluster_name}.as_count()"
            display_type = "bars"
            style {
              palette = "purple"
            }
          }
        }
      }
    }
  }

  widget {
    group_definition {
      title       = "Postgres (DO managed)"
      layout_type = "ordered"

      widget {
        timeseries_definition {
          title       = "CPU Breakdown"
          show_legend = true
          request {
            q            = "avg:do_postgres.cpu_usage_user{*}"
            display_type = "area"
            style {
              palette = "blue"
            }
          }
          request {
            q            = "avg:do_postgres.cpu_usage_system{*}"
            display_type = "area"
            style {
              palette = "orange"
            }
          }
          request {
            q            = "avg:do_postgres.cpu_usage_iowait{*}"
            display_type = "area"
            style {
              palette = "purple"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Memory Used %"
          show_legend = false
          request {
            q            = "avg:do_postgres.mem_used_percent{*}"
            display_type = "line"
            style {
              palette = "orange"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Disk Used %"
          show_legend = false
          request {
            q            = "avg:do_postgres.disk_used_percent{*}"
            display_type = "line"
            style {
              palette = "grey"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "System Load (1m)"
          show_legend = false
          request {
            q            = "avg:do_postgres.system_load1{*}"
            display_type = "line"
            style {
              palette = "red"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Network I/O"
          show_legend = true
          request {
            q            = "avg:do_postgres.net_bytes_recv.count{*}.as_rate()"
            display_type = "line"
            style {
              palette = "blue"
            }
          }
          request {
            q            = "avg:do_postgres.net_bytes_sent.count{*}.as_rate()"
            display_type = "line"
            style {
              palette = "orange"
            }
          }
        }
      }
    }
  }

  widget {
    group_definition {
      title       = "Valkey (DO managed)"
      layout_type = "ordered"

      widget {
        timeseries_definition {
          title       = "CPU Breakdown"
          show_legend = true
          request {
            q            = "avg:do_valkey.cpu_usage_user{*}"
            display_type = "area"
            style {
              palette = "blue"
            }
          }
          request {
            q            = "avg:do_valkey.cpu_usage_system{*}"
            display_type = "area"
            style {
              palette = "orange"
            }
          }
          request {
            q            = "avg:do_valkey.cpu_usage_iowait{*}"
            display_type = "area"
            style {
              palette = "purple"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Memory Used %"
          show_legend = false
          request {
            q            = "avg:do_valkey.mem_used_percent{*}"
            display_type = "line"
            style {
              palette = "orange"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Disk Used %"
          show_legend = false
          request {
            q            = "avg:do_valkey.disk_used_percent{*}"
            display_type = "line"
            style {
              palette = "grey"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "System Load (1m)"
          show_legend = false
          request {
            q            = "avg:do_valkey.system_load1{*}"
            display_type = "line"
            style {
              palette = "red"
            }
          }
        }
      }

      widget {
        timeseries_definition {
          title       = "Network I/O"
          show_legend = true
          request {
            q            = "avg:do_valkey.net_bytes_recv.count{*}.as_rate()"
            display_type = "line"
            style {
              palette = "blue"
            }
          }
          request {
            q            = "avg:do_valkey.net_bytes_sent.count{*}.as_rate()"
            display_type = "line"
            style {
              palette = "orange"
            }
          }
        }
      }
    }
  }
}
