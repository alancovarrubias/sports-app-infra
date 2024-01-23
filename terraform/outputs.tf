output "ansible_ip_address" {
  value = digitalocean_droplet.ansible_server.ipv4_address
}
output "jenkins_ip_address" {
  value = digitalocean_droplet.jenkins_server.ipv4_address
}

