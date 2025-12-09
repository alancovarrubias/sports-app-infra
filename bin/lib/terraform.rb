class Terraform
  def initialize(options)
    @module = options[:module]
    @command = options[:command]
    @output_file = options[:output_file]
    @target = @module == 'prod' ? '-target=module.infra' : ''
  end

  def run
    yield "terraform -chdir=#{@module} init"
    yield "terraform -chdir=#{@module} #{@command} #{@target} -var-file=../terraform.tfvars --auto-approve"
    yield "terraform -chdir=#{@module} output -json > #{@output_file}"
    yield "terraform -chdir=#{@module} output -raw kubeconfig > ~/.kube/sports-app.yaml" if @module == 'prod'
  end
end
