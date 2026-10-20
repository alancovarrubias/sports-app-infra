resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

# Scoped to the Logs pillar only (wayfinder ticket 008/010) -- APM and
# process collection are explicitly disabled; that's the Metrics pillar's
# concern and deliberately left undesigned until later. Note the Datadog
# Agent's core function always reports some baseline host/container metrics
# (unlike nri-bundle's optional subcharts, this isn't cleanly separable) --
# that's an accepted side effect, not a deliberate Metrics-pillar decision.
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
    value = "false"
  }

  set {
    name  = "datadog.networkMonitoring.enabled"
    value = "false"
  }
}
