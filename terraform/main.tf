variable "do_token" {}
variable "public_ssh_key" {}
variable "private_ssh_key" {}
variable "domain_name" {}

module "digitalocean" {
  source         = "./digitalocean"
  do_token       = var.do_token
  domain_name    = var.domain_name
  public_ssh_key = var.public_ssh_key
}

resource "null_resource" "configure_server" {
  triggers = {
    trigger = module.digitalocean.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../ansible"
    command     = "ansible-playbook --inventory ${module.digitalocean.ip_address}, --private-key ${var.private_ssh_key} --user root setup_server.yml"
  }
}

output "server_ip" {
  value = module.digitalocean.ip_address
}
