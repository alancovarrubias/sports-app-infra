module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-2vcpu-2gb"
}

module "sports_app_worker" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-worker"
  droplet_size = "s-2vcpu-2gb"
}
