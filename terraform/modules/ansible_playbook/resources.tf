resource "null_resource" "ansible_playbook" {
  triggers = {
    trigger = var.ip_address
  }
  provisioner "local-exec" {
    working_dir = "../.."
    command = format(
      "./bin/infra_cli.rb -c run -i %s --token %s %s",
      var.ip_address,
      var.do_token,
      var.args,
    )
  }
}
