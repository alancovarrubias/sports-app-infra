variable "do_token" {}
variable "ssh_keys" {}
variable "ssh_key_private" {}
variable "volume_id" {}
variable "domain_name" {}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "Terraform Example"
  public_key = file("/Users/alancovarrubias/.ssh/id_rsa.pub")
}

resource "digitalocean_droplet" "sports-app-web" {
  image    = "ubuntu-22-04-x64"
  name     = "sports-app-web"
  region   = "sfo2"
  size     = "s-1vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_domain" "default" {
  name       = var.domain_name
  ip_address = digitalocean_droplet.sports-app-web.ipv4_address
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "www"
  value  = digitalocean_droplet.sports-app-web.ipv4_address
}

resource "digitalocean_record" "login" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "login"
  value  = digitalocean_droplet.sports-app-web.ipv4_address
}

resource "digitalocean_firewall" "sports-app-firewall" {
  name = "only-22-80-and-443"

  droplet_ids = [digitalocean_droplet.sports-app-web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "null_resource" "configure_server" {
  triggers = {
    trigger = digitalocean_droplet.sports-app-web.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../sports-app-ansible"
    command     = "ansible-playbook --inventory ${digitalocean_droplet.sports-app-web.ipv4_address}, --private-key ${var.ssh_key_private} --user root setup_server.yml"
  }
}

output "ip_address" {
  value = digitalocean_droplet.sports-app-web.ipv4_address
}
