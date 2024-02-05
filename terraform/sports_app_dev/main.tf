terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "sports-app-buck"
    key    = "sports-app-dev/state.tfstate"
    region = "us-west-1"
  }
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

module "digitalocean" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-dev"
  droplet_size = "s-2vcpu-2gb"
}

resource "null_resource" "configure_sports-app-dev" {
  triggers = {
    trigger = module.digitalocean.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, --extra-vars @extra_vars.yml setup_dev_server.yml",
      module.digitalocean.ip_address,
    )
  }
}

output "server_ip" {
  value = module.digitalocean.ip_address
}

