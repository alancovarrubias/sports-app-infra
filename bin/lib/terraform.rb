class Terraform
  def initialize(options)
    @module = options[:module]
    @command = options[:command]
    @output_file = options[:output_file]
  end

  def run
    yield "terraform -chdir=#{@module} init"
    if @module == 'prod'
      yield "terraform -chdir=#{@module} #{@command} -target=module.infra -var-file=../terraform.tfvars --auto-approve"
      yield "terraform -chdir=#{@module} #{@command} -target=module.k8s -var-file=../terraform.tfvars --auto-approve"
      yield "terraform -chdir=#{@module} output -json > #{@output_file}"
      yield "terraform -chdir=#{@module} output -raw kubeconfig > ~/.kube/sports-app.yaml"
    else
      yield "terraform -chdir=#{@module} #{@command} -var-file=../terraform.tfvars --auto-approve"
      yield "terraform -chdir=#{@module} output -json > #{@output_file}"
    end
  end
end
