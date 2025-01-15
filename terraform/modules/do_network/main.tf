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
variable "domain_name" {}
variable "web_id" {}
variable "web_ip" {}
variable "worker_ip" {}
variable "ansible_ip" {}
