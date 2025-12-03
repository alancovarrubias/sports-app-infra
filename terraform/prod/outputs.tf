output "k8s_cluster_id" { value = digitalocean_kubernetes_cluster.app.id }
output "registry_name" { value = digitalocean_container_registry.registry.endpoint }
output "database_uri" {
  value = digitalocean_database_cluster.db.uri
  sensitive = true
}
output "cache_uri" {
  value = digitalocean_database_cluster.cache.uri
  sensitive = true
}
