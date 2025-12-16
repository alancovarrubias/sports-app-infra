class Terraform
  WORKING_DIR = File.join(InfraCLI::ROOT_DIR, 'terraform')
  def initialize(options)
    @module = options[:module]
    @command = options[:command]
    @output_file = options[:output_file]
  end

  def run
    commands = [
      'init',
      "#{@command} -var-file=../terraform.tfvars --auto-approve",
      "output -json > #{@output_file}"
    ]
    run_commands(commands)
  end

  def prod_infra
    commands = [
      'init',
      "#{@command} -target=module.infra -var-file=../terraform.tfvars --auto-approve",
      "output -raw kubeconfig > #{InfraCLI::KUBE_CONFIG}",
      "output -json > #{@output_file}"
    ]
    run_commands(commands)
  end

  def prod_kube
    commands = [
      "#{@command} -target=module.k8s -var-file=../terraform.tfvars --auto-approve"
    ]
    run_commands(commands)
  end

  def prod_destroy
    commands = [
      "#{@command} -target=module.k8s -var-file=../terraform.tfvars --auto-approve",
      "#{@command} -target=module.infra -var-file=../terraform.tfvars --auto-approve"
    ]
    run_commands(commands)
  end

  def run_commands(commands)
    Dir.chdir(WORKING_DIR) do
      commands.each do |command|
        system("terraform -chdir=#{@module} #{command}")
      end
    end
  end
end
