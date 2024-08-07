module "sports_app_web" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-web"
  droplet_size = "s-2vcpu-4gb"
}

module "sports_app_web_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.sports_app_web.ip_address
  args       = "-m web -e dev"
}

module "sports_app_ansible" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-ansible"
  droplet_size = "s-2vcpu-4gb"
}

module "sports_app_ansible_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.sports_app_ansible.ip_address
  args = format(
    "-m ansible -w %s",
    module.sports_app_web.ip_address
  )
}
