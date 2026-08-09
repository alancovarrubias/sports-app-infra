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
