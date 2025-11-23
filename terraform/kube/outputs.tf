output "k8s_cluster_id" { value = digitalocean_kubernetes_cluster.main.id }
output "k8s_cluster_name" { value = digitalocean_kubernetes_cluster.main.name }
output "db_host" { value = digitalocean_database_cluster.postgres.host }
output "db_port" { value = digitalocean_database_cluster.postgres.port }
output "db_user" { value = digitalocean_database_cluster.postgres.user }
output "db_password" {
  value     = digitalocean_database_cluster.postgres.password
  sensitive = true
}
output "db_name" { value = digitalocean_database_cluster.postgres.database }
