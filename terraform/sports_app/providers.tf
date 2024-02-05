terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "sports-app-buck"
    key    = "sports-app/state.tfstate"
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
