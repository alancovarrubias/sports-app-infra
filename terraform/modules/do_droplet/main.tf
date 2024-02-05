terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {}
variable "droplet_name" {}
variable "droplet_size" {}

data "digitalocean_ssh_key" "ssh_key" {
  name = "SSH Key"
}

resource "digitalocean_droplet" "sports-app-web" {
  image    = "ubuntu-22-04-x64"
  name     = var.droplet_name
  region   = "sfo2"
  size     = var.droplet_size
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]
}

output "ip_address" {
  value = digitalocean_droplet.sports-app-web.ipv4_address
}
