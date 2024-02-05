module "sports-app" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app"
  droplet_size = "s-2vcpu-2gb"
}
