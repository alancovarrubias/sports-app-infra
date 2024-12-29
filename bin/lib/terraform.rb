module Terraform
  module_function

  def run(options)
    yield "terraform -chdir=#{options[:module]} init"
    yield "terraform -chdir=#{options[:module]} #{options[:command]} -var-file=../terraform.tfvars --auto-approve"
  end
end
