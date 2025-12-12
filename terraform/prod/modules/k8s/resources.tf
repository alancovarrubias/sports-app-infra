resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
}

resource "kubernetes_deployment" "football" {
  metadata {
    name = "football"
  }

  spec {
    selector {
      match_labels = {
        app = "football"
      }
    }

    template {
      metadata {
        labels = {
          app = "football"
        }
      }

      spec {
        container {
          name  = "football"
          image = "${var.registry_name}/football:dev"

          env {
            name  = "DATABASE_URL"
            value = var.db_uri
          }

          env {
            name  = "REDIS_URL_SIDEKIQ"
            value = var.cache_uri
          }

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}
