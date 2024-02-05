resource "digitalocean_domain" "default" {
  name       = var.domain_name
  ip_address = module.sports-app.ip_address
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "www"
  value  = module.sports-app.ip_address
}
