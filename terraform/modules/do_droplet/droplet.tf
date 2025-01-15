data "digitalocean_ssh_key" "ssh_key" {
  name = "SSH Key"
}

resource "digitalocean_droplet" "droplet_instance" {
  image    = "ubuntu-22-04-x64"
  name     = var.droplet_name
  region   = "sfo2"
  size     = var.droplet_size
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]
}


resource "null_resource" "ansible_playbook" {
  depends_on = [
    digitalocean_droplet.droplet_instance,
  ]
  triggers = {
    trigger = digitalocean_droplet.droplet_instance.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../.."
    command = format(
      "./bin/infra_cli.rb -c run -i %s --token %s %s",
      digitalocean_droplet.droplet_instance.ipv4_address,
      var.do_token,
      var.args,
    )
  }
}
