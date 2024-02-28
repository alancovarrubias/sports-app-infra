
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
  args       = "-m jenkins"
}
