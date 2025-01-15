module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-4vcpu-8gb"
  args         = "-m web -e dev"
}
