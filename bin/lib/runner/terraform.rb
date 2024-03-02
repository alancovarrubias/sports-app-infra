module Runner
  class Terraform
    TERRAFORM_DIR = '$(pwd)/terraform'.freeze
    def initialize(options)
      @command = options[:command]
      @module = options[:module]
    end

    def run
      run_command('init')
      run_command("#{@command} -var-file=#{TERRAFORM_DIR}/terraform.tfvars --auto-approve")
    end

    def run_command(cmd)
      system("terraform -chdir=\"#{TERRAFORM_DIR}/#{@module}\" #{cmd}")
    end
  end
end
