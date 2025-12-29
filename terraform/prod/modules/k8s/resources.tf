resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "digitalocean_domain" "main" {
  name       = "alancovarrubias.com"
  ip_address = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}

resource "digitalocean_record" "client_domain" {
  depends_on = [
    helm_release.nginx_ingress,
    data.kubernetes_service.nginx_ingress
  ]

  domain = digitalocean_domain.main.name
  type   = "A"
  name   = "client"
  value  = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}
