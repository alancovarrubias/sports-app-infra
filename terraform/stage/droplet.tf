module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-1vcpu-2gb"
}

module "sports_app_web_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.sports_app_web.ip_address
  args       = "-m web -e stage"
  depends_on = [module.sports_app_web]
}

module "sports_app_worker" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-worker"
  droplet_size = "s-2vcpu-4gb"
}

module "sports_app_worker_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.sports_app_worker.ip_address
  args = format(
    "-m worker --web_ip %s -e stage",
    module.sports_app_web.ip_address
  )
  depends_on = [module.sports_app_web, module.sports_app_worker]
}

module "ansible_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "ansible-server"
  droplet_size = "s-1vcpu-1gb"
}

module "ansible_server_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.ansible_server.ip_address
  args = format(
    "-m ansible --web_ip %s --worker_ip %s",
    module.sports_app_web.ip_address,
    module.sports_app_worker.ip_address
  )
  depends_on = [module.sports_app_web, module.sports_app_worker, module.ansible_server]
}
