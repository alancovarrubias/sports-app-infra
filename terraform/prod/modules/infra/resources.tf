resource "digitalocean_kubernetes_cluster" "app" {
  name    = "sports-app-cluster"
  region  = "sfo3"
  version = "latest"

  node_pool {
    name       = "app-pool"
    size       = "s-4vcpu-8gb"
    node_count = 1
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 5
  }
}

resource "digitalocean_database_cluster" "db" {
  name       = "sports-db"
  engine     = "pg"
  version    = "18"
  size       = "db-s-1vcpu-1gb"
  region     = "sfo3"
  node_count = 1
}

resource "digitalocean_database_cluster" "cache" {
  name       = "sports-cache"
  engine     = "valkey"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "sfo3"
  node_count = 1
}
