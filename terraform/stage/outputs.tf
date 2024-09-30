output "web_ip" {
  value = module.sports_app_web.ip_address
}

output "worker_ip" {
  value = module.sports_app_worker.ip_address
}

output "ansible_ip" {
  value = module.ansible_server.ip_address
}

