module Runners
  class Terraform
    include Constants
    def initialize(options)
      @options = options
    end

    def init
      build_command('init')
    end

    def destroy(target = nil)
      apply_destroy('destroy', target)
    end

    def apply(target = nil)
      apply_destroy('apply', target)
    end

    def apply_destroy(command, target)
      commands = []
      commands << command
      commands << "-target=module.#{target}" if target
      commands << '-var-file=../terraform.tfvars --auto-approve'
      build_command(commands.join(' '))
    end

    def output
      build_command("output -json > #{@options[:output_file]}")
    end

    def output_raw
      build_command("output -raw kubeconfig > #{KUBECONFIG}")
    end

    def build_command(command)
      "terraform -chdir=#{@options[:module]} #{command}"
    end
  end
end
