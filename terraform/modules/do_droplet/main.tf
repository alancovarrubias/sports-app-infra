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


output "id" {
  value = digitalocean_droplet.droplet_instance.id
}

output "ip_address" {
  value = digitalocean_droplet.droplet_instance.ipv4_address
}
