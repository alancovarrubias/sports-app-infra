module "sports_app_kube" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-kube"
  droplet_size = "s-2vcpu-4gb"
  args         = "-m kube"
}
