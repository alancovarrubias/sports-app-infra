data "digitalocean_kubernetes_versions" "app" {
  version_prefix = "1.36."
}

resource "digitalocean_kubernetes_cluster" "app" {
  name    = "sports-app-cluster"
  region  = "nyc3"
  version = data.digitalocean_kubernetes_versions.app.latest_version

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
  region     = "nyc3"
  node_count = 1
}

resource "digitalocean_database_cluster" "cache" {
  name       = "sports-cache"
  engine     = "valkey"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc3"
  node_count = 1
}
