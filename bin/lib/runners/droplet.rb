module Runners
  # Shared shape for environments backed by a single DigitalOcean droplet
  # running Docker Compose (Dev, Mercor): one terraform apply, then an
  # Ansible playbook to configure the droplet.
  class Droplet < Base
    def apply
      run_terraform('init', 'apply', 'output')
      ansible_command
    end

    def destroy
      run_terraform('init', 'destroy', 'output')
    end

    def run
      ansible_command
    end

    def database
      run_ansible(
        playbook: 'database_cmd',
        inventory: outputs['web_ip']['value'],
        tags: @options[:tags],
        env: @options[:env]
      )
    end

    private

    def default_tags
      nil
    end

    def ansible_command
      run_ansible(
        playbook: playbook,
        inventory: outputs['web_ip']['value'],
        tags: @options[:tags] || default_tags,
        env: @options[:env]
      )
    end
  end
end
