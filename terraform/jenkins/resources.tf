module "jenkins_server" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "jenkins-server"
  droplet_size = "s-2vcpu-4gb"
  args         = "-m jenkins"
}
