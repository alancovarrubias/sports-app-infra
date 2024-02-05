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
