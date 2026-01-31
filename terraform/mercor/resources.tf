module "mercor_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "mercor-web"
  droplet_size = "s-4vcpu-8gb"
}
