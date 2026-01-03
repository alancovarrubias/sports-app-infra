module Runners
  class Terraform
    include Constants
    def initialize(options)
      @options = options
    end

    def run(command)
      if command.start_with?('apply', 'destroy')
        action, target = command.split('_', 2)
        action_command(action, target)
      else
        send(command)
      end
    end

    private

    def init
      terraform_command('init')
    end

    def output
      terraform_command("output -json > #{@options[:output_file]}")
    end

    def kubeconfig
      terraform_command("output -raw kubeconfig > #{KUBECONFIG}")
    end

    def action_command(command, target)
      commands = []
      commands << command
      commands << "-target=module.#{target}" if target
      commands << '-var-file=../terraform.tfvars --auto-approve'
      terraform_command(commands.join(' '))
    end

    def terraform_command(command)
      "terraform -chdir=#{@options[:module]} #{command}"
    end
  end
end
