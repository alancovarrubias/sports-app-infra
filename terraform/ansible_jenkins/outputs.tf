output "ansible_ip_address" {
  value = module.ansible_server.ip_address
}
output "jenkins_ip_address" {
  value = module.jenkins_server.ip_address
}
