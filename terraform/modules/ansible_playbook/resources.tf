resource "null_resource" "ansible_playbook" {
  triggers = {
    trigger = var.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../../ansible"
    command = format(
      "ansible-playbook --inventory %s, %s %s",
      var.ip_address,
      var.vars_string,
      var.playbook,
    )
  }
}
