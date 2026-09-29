resource "kubernetes_namespace" "newrelic" {
  metadata {
    name = "newrelic"
  }
}

# Scoped to the Logs pillar only (wayfinder ticket 008/010) -- infrastructure,
# kube-state-metrics, and Prometheus scraping are the Metrics pillar's
# concern and deliberately left disabled until that's designed.
resource "helm_release" "newrelic_bundle" {
  name       = "newrelic-bundle"
  repository = "https://helm-charts.newrelic.com"
  chart      = "nri-bundle"
  namespace  = kubernetes_namespace.newrelic.metadata[0].name

  set {
    name  = "global.licenseKey"
    value = var.license_key
  }

  set {
    name  = "global.cluster"
    value = var.cluster_name
  }

  set {
    name  = "logging.enabled"
    value = "true"
  }

  set {
    name  = "infrastructure.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  set {
    name  = "ksm.enabled"
    value = "false"
  }

  set {
    name  = "kubeEvents.enabled"
    value = "false"
  }

  set {
    name  = "webhook.enabled"
    value = "false"
  }
}
