module "digitalocean" {
  source       = "../modules/do_droplet"
  do_token     = var.do_token
  droplet_name = "sports-app-dev"
  droplet_size = "s-2vcpu-2gb"
}

resource "null_resource" "configure_sports-app-dev" {
  triggers = {
    trigger = module.digitalocean.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, --extra-vars @extra_vars.yml setup_dev_server.yml",
      module.digitalocean.ip_address,
    )
  }
}
