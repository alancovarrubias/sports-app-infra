module Runner
  class Terraform
    TERRAFORM_DIR = '$(pwd)/terraform'.freeze
    def initialize(options)
      @command = options[:command]
      @module = options[:module]
    end

    def run
      "terraform -chdir=#{TERRAFORM_DIR}/#{@module} #{@command} -var-file=#{TERRAFORM_DIR}/terraform.tfvars --auto-approve"
    end
  end
end
