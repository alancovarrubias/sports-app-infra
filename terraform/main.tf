resource "digitalocean_ssh_key" "default" {
  name       = "SSH Key"
  public_key = file(var.public_ssh_key)
}

resource "digitalocean_droplet" "ansible_server" {
  image    = "ubuntu-22-04-x64"
  name     = "ansible-server"
  region   = "sfo2"
  size     = "s-2vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_droplet" "jenkins_server" {
  image    = "ubuntu-22-04-x64"
  name     = "jenkins-server"
  region   = "sfo2"
  size     = "s-2vcpu-2gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

variable "ansible_command_template" {
  default = "ansible-playbook --vault-password-file ~/.vault_pass.txt --inventory %s, -e target_host_ip=%s --private-key %s --user root %s"
}

resource "null_resource" "configure_jenkins_server" {
  triggers = {
    trigger = digitalocean_droplet.jenkins_server.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../ansible"
    command = format(
      var.ansible_command_template,
      digitalocean_droplet.jenkins_server.ipv4_address,
      digitalocean_droplet.jenkins_server.ipv4_address,
      var.private_ssh_key,
      "setup_jenkins.yml"
    )
  }
}

resource "null_resource" "configure_ansible_server" {
  triggers = {
    trigger = digitalocean_droplet.ansible_server.ipv4_address
  }
  provisioner "local-exec" {
    working_dir = "../ansible"
    command = format(
      var.ansible_command_template,
      digitalocean_droplet.ansible_server.ipv4_address,
      digitalocean_droplet.ansible_server.ipv4_address,
      var.private_ssh_key,
      "setup_ansible.yml"
    )
  }
}
