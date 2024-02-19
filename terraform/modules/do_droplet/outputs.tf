output "id" {
  value = digitalocean_droplet.droplet_instance.id
}

output "ip_address" {
  value = digitalocean_droplet.droplet_instance.ipv4_address
}
