terraform {
  required_version = ">= 0.12"
  backend "s3" {
    key    = "kube/state.tfstate"
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
