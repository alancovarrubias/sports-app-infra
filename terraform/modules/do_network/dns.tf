data "digitalocean_domain" "my_domain" {
  name = var.domain_name
}

resource "digitalocean_record" "default" {
  domain = data.digitalocean_domain.my_domain.id
  type   = "A"
  name   = "@"
  value  = var.web_ip
}

resource "digitalocean_record" "www" {
  domain = data.digitalocean_domain.my_domain.id
  type   = "A"
  name   = "www"
  value  = var.web_ip
}
