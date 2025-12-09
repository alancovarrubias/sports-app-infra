output "k8s_cluster_id" {
  value = module.infra.k8s_cluster_id
}

output "kubeconfig" {
  value     = module.infra.kubeconfig
  sensitive = true
}

output "registry_name" {
  value = module.infra.registry_name
}

output "database_uri" {
  value     = module.infra.database_uri
  sensitive = true
}

output "cache_uri" {
  value     = module.infra.cache_uri
  sensitive = true
}
