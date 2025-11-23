resource "digitalocean_kubernetes_cluster" "main" {
  name    = "sports-app-cluster"
  region  = "sfo3"
  version = "latest"

  node_pool {
    name       = "app-pool"
    size       = "s-2vcpu-4gb"
    node_count = 1
  }
}

resource "digitalocean_container_registry" "sports" {
  name                   = "sports" # registry name
  region                 = "sfo3"   # optional, defaults to your account region
  subscription_tier_slug = "basic"  # optional: starter, basic, professional
}

resource "digitalocean_database_cluster" "postgres" {
  name       = "sports-db"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-1gb"
  region     = "sfo3"
  node_count = 1
}
