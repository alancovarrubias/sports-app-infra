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

resource "null_resource" "configure_jenkins_server" {
  triggers = {
    trigger = module.ansible_server.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, -e ansible_ip=%s --extra-vars @extra_vars.yml --skip-tags plugins setup_jenkins.yml",
      module.jenkins_server.ip_address,
      module.ansible_server.ip_address,
    )
  }
}

resource "null_resource" "configure_ansible_server" {
  triggers = {
    trigger = module.ansible_server.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, --extra-vars @extra_vars.yml setup_ansible.yml",
      module.ansible_server.ip_address,
    )
  }
}
