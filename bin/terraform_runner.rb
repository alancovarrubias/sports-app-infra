class TerraformRunner
  def initialize(options)
    @command = options[:command]
    @module = options[:module]
  end

  def run
    run_command('init')
    run_command("#{@command} -var-file=../terraform.tfvars --auto-approve")
  end

  def run_command(cmd)
    tf_cmd = "terraform -chdir=\"$(pwd)/terraform/#{@module}\" #{cmd}"
    system(tf_cmd)
  end
end
