module Runners
  class Mercor < Base
    def apply
      run_terraform(
        'init',
        'apply',
        'output'
      )
      ansible_command
    end

    def destroy
      run_terraform(
        'init',
        'destroy',
        'output'
      )
    end

    def run
      ansible_command
    end

    private

    def ansible_command
      run_ansible(
        playbook: 'setup_mercor',
        inventory: outputs['web_ip']['value'],
        tags: @options[:tags]
      )
    end
  end
end
