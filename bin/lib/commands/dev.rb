module Commands
  class Dev < Base
    def apply
      run_terraform(
        @terraform_runner.init,
        @terraform_runner.apply,
        @terraform_runner.output
      )
      ansible_options
    end

    def destroy
      run_terraform(
        @terraform_runner.init,
        @terraform_runner.destroy,
        @terraform_runner.output
      )
    end

    def run
      ansible_options
    end

    private

    def ansible_options
      run_ansible(
        playbook: 'setup_dev',
        inventory: @outputs['web_ip']['value'],
        tags: @options[:tags] || %w[setup server docker create client dev],
        env: @options[:module]
      )
    end
  end
end
