module Commands
  class Dev < Base
    def apply
      run_terraform(terraform_commands)
      run_ansible(ansible_commands)
    end

    def destroy
      run_terraform(terraform_commands)
    end

    def run
      run_ansible(ansible_commands)
    end

    private

    def terraform_commands
      [
        @terraform_runner.init,
        @terraform_runner.apply,
        @terraform_runner.output
      ]
    end

    def ansible_commands
      @ansible_runner.command(
        playbook: 'setup_dev',
        inventory: @outputs['web_ip']['value'],
        tags: @options[:tags] || %w[setup server docker create client dev],
        env: @options[:module]
      )
    end
  end
end
