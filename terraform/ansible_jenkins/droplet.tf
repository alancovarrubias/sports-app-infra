
module "ansible_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "ansible-server"
  droplet_size = "s-1vcpu-1gb"
}

module "jenkins_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "jenkins-server"
  droplet_size = "s-2vcpu-4gb"
}

module "jenkins_server_playbook" {
  source     = "../modules/ansible_playbook"
  do_token   = var.do_token
  ip_address = module.jenkins_server.ip_address
  playbook   = "setup_jenkins.yml"
  vars_string = format(
    "-e ansible_ip=%s --extra-vars @extra_vars.yml --skip-tags plugins",
    module.ansible_server.ip_address
  )
}

module "ansible_server_playbook" {
  source      = "../modules/ansible_playbook"
  do_token    = var.do_token
  ip_address  = module.ansible_server.ip_address
  playbook    = "setup_ansible.yml"
  vars_string = "--extra-vars @extra_vars.yml"
}
