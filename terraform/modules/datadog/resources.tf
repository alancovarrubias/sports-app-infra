resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
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
