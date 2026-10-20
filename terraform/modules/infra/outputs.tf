output "k8s_cluster_id" { value = digitalocean_kubernetes_cluster.app.id }
output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.app.kube_config[0].raw_config
  sensitive = true
}
output "database_uri" {
  value     = digitalocean_database_cluster.db.uri
  sensitive = true
}
output "cache_uri" {
  value     = digitalocean_database_cluster.cache.uri
  sensitive = true
}
output "mongo_uri" {
  value     = digitalocean_database_cluster.mongo.uri
  sensitive = true
}

output "database_metrics_endpoint" {
  value = digitalocean_database_cluster.db.metrics_endpoints[0]
}
output "cache_metrics_endpoint" {
  value = digitalocean_database_cluster.cache.metrics_endpoints[0]
}

output "metrics_credentials_username" {
  value = data.digitalocean_database_metrics_credentials.this.username
}
output "metrics_credentials_password" {
  value     = data.digitalocean_database_metrics_credentials.this.password
  sensitive = true
}
