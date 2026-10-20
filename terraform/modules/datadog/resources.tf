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
