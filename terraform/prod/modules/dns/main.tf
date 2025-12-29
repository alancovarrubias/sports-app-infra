
resource "digitalocean_domain" "main" {
  name       = var.domain_name
  ip_address = var.ingress_ip
}

resource "digitalocean_record" "client_domain" {
  depends_on = [digitalocean_domain.main]
  domain     = digitalocean_domain.main.name
  type       = "A"
  name       = "client"
  value      = var.ingress_ip
}
