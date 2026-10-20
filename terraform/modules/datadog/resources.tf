resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

# DO's managed Postgres/Valkey each expose a Prometheus-format metrics
# endpoint (metrics_endpoints on digitalocean_database_cluster) over a
# self-signed cert (tls_verify off -- that cert isn't signed by a public CA)
# gated by an account-wide metrics credential (digitalocean_database_metrics_
# credentials) -- NOT the per-cluster DB admin user/password, which 401s
# against this endpoint (confirmed empirically). MongoDB has no such
# endpoint, so it isn't covered here.
#
# datadog.confd keys land as flat files directly under /conf.d (no "/" --
# Kubernetes ConfigMap data keys can't contain one, and the chart's
# advancedConfd nesting only exists for clusterAgent, not the node Agent),
# so both instances live in one openmetrics.yaml, matching the check name
# the Agent looks for.
locals {
  confd_values = yamlencode({
    datadog = {
      confd = {
        "openmetrics.yaml" = yamlencode({
          instances = [
            {
              openmetrics_endpoint = var.database_metrics_endpoint
              namespace            = "do_postgres"
              metrics              = [".*"]
              username             = var.metrics_credentials_username
              password             = var.metrics_credentials_password
              tls_verify           = false
            },
            {
              openmetrics_endpoint = var.cache_metrics_endpoint
              namespace            = "do_valkey"
              metrics              = [".*"]
              username             = var.metrics_credentials_username
              password             = var.metrics_credentials_password
              tls_verify           = false
            }
          ]
        })
      }
    }
  })
}

# Logs pillar (wayfinder ticket 008/010) plus a first pass at the Metrics
# pillar (ticket 008/datadog-infra-metrics branch): process + network
# telemetry turned on. APM stays off -- enabling the trace-receiving port
# alone is a no-op without actual tracing instrumentation in each service,
# a bigger, separate decision. The Agent's core infra/container metrics
# (CPU, memory, pod health) were never behind a flag here -- that's always
# been on by default since the Agent was first deployed.
resource "helm_release" "datadog" {
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = kubernetes_namespace.datadog.metadata[0].name
  values     = [local.confd_values]

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.api_key
  }

  set {
    name  = "datadog.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "datadog.logs.enabled"
    value = "true"
  }

  set {
    name  = "datadog.logs.containerCollectAll"
    value = "true"
  }

  # konnectivity-agent's routine tunnel chatter was showing up status:error
  # with no actual problem (see the monitor's own comment), cluttering the
  # Logs UI. Scoped to this one component, not all of kube-system -- CoreDNS
  # also lives there and DNS failures are a real thing worth being able to
  # debug; konnectivity-agent's own logs matter too if the tunnel it
  # provides ever breaks (kubectl exec/logs/port-forward all depend on it).
  set {
    name  = "datadog.containerExcludeLogs"
    value = "kube_container_name:konnectivity-agent"
  }

  set {
    name  = "datadog.apm.portEnabled"
    value = "false"
  }

  set {
    name  = "datadog.processAgent.enabled"
    value = "true"
  }

  set {
    name  = "datadog.networkMonitoring.enabled"
    value = "true"
  }
}
