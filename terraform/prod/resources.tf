module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-1vcpu-2gb"
  args         = "-m web -e prod"
}

module "sports_app_worker" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-worker"
  droplet_size = "s-2vcpu-2gb"
  args = format(
    "-m worker --web_ip %s -e prod",
    module.sports_app_web.ip_address
  )
}

module "ansible_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "ansible-server"
  droplet_size = "s-1vcpu-1gb"
  args = format(
    "-m ansible --web_ip %s --worker_ip %s",
    module.sports_app_web.ip_address,
    module.sports_app_worker.ip_address
  )
}

module "sports_app_network" {
  source      = "../modules/do_network"
  do_token    = var.do_token
  domain_name = var.domain_name
  web_id      = module.sports_app_web.id
  web_ip      = module.sports_app_web.ip_address
  worker_ip   = module.sports_app_worker.ip_address
  ansible_ip  = module.ansible_server.ip_address
}
