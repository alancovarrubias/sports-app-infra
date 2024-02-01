resource "digitalocean_ssh_key" "default" {
  name       = "SSH Key"
  public_key = file(var.public_ssh_key)
}

resource "digitalocean_droplet" "ansible_server" {
  image    = "ubuntu-22-04-x64"
  name     = "ansible-server"
  region   = "sfo2"
  size     = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_droplet" "jenkins_server" {
  image    = "ubuntu-22-04-x64"
  name     = "jenkins-server"
  region   = "sfo2"
  size     = "s-2vcpu-4gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "null_resource" "configure_jenkins_server" {
  triggers = {
    trigger = digitalocean_droplet.jenkins_server.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, -e target_host_ip=%s -e ansible_ip=%s --extra-vars @extra_vars.yml --skip-tags plugins setup_jenkins.yml",
      digitalocean_droplet.jenkins_server.ipv4_address,
      digitalocean_droplet.jenkins_server.ipv4_address,
      digitalocean_droplet.ansible_server.ipv4_address,
    )
  }
}

resource "null_resource" "configure_ansible_server" {
  triggers = {
    trigger = digitalocean_droplet.ansible_server.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, -e target_host_ip=%s --extra-vars @extra_vars.yml setup_ansible.yml",
      digitalocean_droplet.ansible_server.ipv4_address,
      digitalocean_droplet.ansible_server.ipv4_address,
    )
  }
}
