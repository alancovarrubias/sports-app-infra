resource "digitalocean_record" "www" {
  domain = var.domain_name
  type   = "A"
  name   = "www"
  value  = module.sports_app_web.ip_address
}
