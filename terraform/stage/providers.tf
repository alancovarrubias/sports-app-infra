terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/sports-app.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/sports-app.yaml"
  }
}

provider "digitalocean" {
  token = var.do_token
}
