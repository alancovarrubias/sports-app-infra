data "digitalocean_ssh_key" "ssh_key" {
  name = "SSH Key"
}

resource "digitalocean_droplet" "sports-app-web" {
  image    = "ubuntu-22-04-x64"
  name     = "sports-app-server"
  region   = "sfo2"
  size     = "s-2vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]
}
