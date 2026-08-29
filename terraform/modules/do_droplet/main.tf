terraform {
  required_version = ">= 1.5.0"

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

variable "do_token" {
  type = string
}
variable "droplet_name" {
  type = string
}
variable "droplet_size" {
  type = string
}


output "id" {
  value = digitalocean_droplet.droplet_instance.id
}

output "ip_address" {
  value = digitalocean_droplet.droplet_instance.ipv4_address
}
