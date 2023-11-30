provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "SSH Key"
  public_key = file(var.public_ssh_key)
}

resource "digitalocean_droplet" "sports-app-web" {
  image    = "ubuntu-22-04-x64"
  name     = "sports-app-web"
  region   = "sfo2"
  size     = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

# resource "digitalocean_domain" "default" {
#   name       = var.domain_name
#   ip_address = digitalocean_droplet.sports-app-web.ipv4_address
# }
# 
# resource "digitalocean_record" "www" {
#   domain = digitalocean_domain.default.id
#   type   = "A"
#   name   = "www"
#   value  = digitalocean_droplet.sports-app-web.ipv4_address
# }
# 
# resource "digitalocean_firewall" "sports-app-firewall" {
#   name = "only-22-80-and-443"
# 
#   droplet_ids = [digitalocean_droplet.sports-app-web.id]
# 
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "22"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "80"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "443"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   inbound_rule {
#     protocol         = "icmp"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   outbound_rule {
#     protocol              = "tcp"
#     port_range            = "1-65535"
#     destination_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   outbound_rule {
#     protocol              = "udp"
#     port_range            = "1-65535"
#     destination_addresses = ["0.0.0.0/0", "::/0"]
#   }
# 
#   outbound_rule {
#     protocol              = "icmp"
#     destination_addresses = ["0.0.0.0/0", "::/0"]
#   }
# }
