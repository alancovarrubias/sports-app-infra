resource "digitalocean_record" "www" {
  domain = var.domain_name
  type   = "A"
  name   = "www"
  value  = module.sports-app.ip_address
}
