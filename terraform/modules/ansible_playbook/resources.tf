resource "null_resource" "ansible_playbook" {
  triggers = {
    trigger = var.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../.."
    command = format(
      "./bin/infra_cli -c run -i %s %s",
      var.ip_address,
      var.args,
    )
  }
}
