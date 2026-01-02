resource "digitalocean_container_registry" "registry" {
  name                   = "sports"
  region                 = "sfo3"
  subscription_tier_slug = "basic"
}
