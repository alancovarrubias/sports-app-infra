module Terraform
  module_function

  def run(options)
    yield "terraform -chdir=#{options[:module]} init"
    yield "terraform -chdir=#{options[:module]} #{options[:command]} -var-file=../terraform.tfvars --auto-approve"
    yield "terraform -chdir=#{options[:module]} output -json > ../ansible/outputs/#{options[:module]}.json"
  end
end
