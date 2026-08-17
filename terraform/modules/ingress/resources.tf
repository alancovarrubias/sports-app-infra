resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
