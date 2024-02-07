
module "ansible_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "ansible-server"
  droplet_size = "s-1vcpu-1gb"
}

module "ansible_server_playbook" {
  source      = "../modules/ansible_playbook"
  do_token    = var.do_token
  ip_address  = module.ansible_server.ip_address
  playbook    = "setup_ansible.yml"
  vars_string = "--extra-vars @extra_vars.yml"
}
