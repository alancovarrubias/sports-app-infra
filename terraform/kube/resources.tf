resource "digitalocean_kubernetes_cluster" "main" {
  name    = "sports-app-cluster"
  region  = "sfo3"
  version = "latest"

  node_pool {
    name       = "app-pool"
    size       = "s-2vcpu-4gb"
    node_count = 1
  }
}

resource "digitalocean_container_registry" "sports" {
  name                   = "sports" # registry name
  region                 = "sfo3"   # optional, defaults to your account region
  subscription_tier_slug = "basic"  # optional: starter, basic, professional
}

resource "null_resource" "attach_registry" {
  provisioner "local-exec" {
    command = "doctl kubernetes cluster registry add ${digitalocean_kubernetes_cluster.main.name}"
  }
  depends_on = [digitalocean_container_registry.sports, digitalocean_kubernetes_cluster.main]
}

resource "null_resource" "ansible_cluster" {
  depends_on = [
    digitalocean_kubernetes_cluster.main
  ]

  triggers = {
    cluster_id = digitalocean_kubernetes_cluster.main.id
  }

  provisioner "local-exec" {
    working_dir = "../.."
    command = format(
      "./bin/infra_cli.rb -c run -k %s --token %s -m kube",
      digitalocean_kubernetes_cluster.main.id,
      var.do_token,
    )
  }
}
