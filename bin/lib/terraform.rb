class Terraform
  def initialize(options)
    @module = options[:module]
    @command = options[:command]
    @output_file = options[:output_file]
  end

  def run
    yield "terraform -chdir=#{@module} init"
    yield "terraform -chdir=#{@module} #{@command} -var-file=../terraform.tfvars --auto-approve"
    yield "terraform -chdir=#{@module} output -json > #{@output_file}"
    yield "terraform -chdir=#{@module} output -raw kubeconfig > ~/.kube/sports-app.yaml"
  end
end
