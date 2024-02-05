module "sports-app-dev" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-dev"
  droplet_size = "s-2vcpu-2gb"
}

module "sports-app-dev_playbook" {
  source      = "../modules/ansible_playbook"
  do_token    = var.do_token
  vars_string = "--extra-vars @extra_vars.yml"
  ip_address  = module.sports-app-dev.ip_address
  playbook    = "setup_sports_app_dev.yml"
}
