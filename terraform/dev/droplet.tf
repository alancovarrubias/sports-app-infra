module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-2vcpu-4gb"
}

module "sports_app_web_playbook" {
  source      = "../modules/ansible_playbook"
  do_token    = var.do_token
  vars_string = "--extra-vars @extra_vars.yml"
  ip_address  = module.sports_app_web.ip_address
  playbook    = "setup_sports_app_dev.yml"
}

module "sports_app_worker" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-worker"
  droplet_size = "s-2vcpu-4gb"
}

module "sports_app_worker_playbook" {
  source   = "../modules/ansible_playbook"
  do_token = var.do_token
  vars_string = format(
    "--extra-vars @extra_vars.yml -e web_ip=%s",
    module.sports_app_web.ip_address
  )
  ip_address = module.sports_app_worker.ip_address
  playbook   = "setup_sports_app_worker.yml"
}
