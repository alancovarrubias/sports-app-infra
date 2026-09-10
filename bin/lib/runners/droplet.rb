module Runners
  # Environments backed by a single DigitalOcean droplet running Docker
  # Compose (dev, mercor): one terraform apply, then an Ansible playbook to
  # configure the droplet. Dev is the only one with a default tag set, since
  # an untagged run there should still bootstrap a fresh machine end to end;
  # mercor has no defaults, so an untagged run means "run everything".
  class Droplet < Base
    DEV_DEFAULT_TAGS = %w[setup server docker create client dev].freeze

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

    def playbook
      "setup_#{@options[:env]}"
    end

    def default_tags
      DEV_DEFAULT_TAGS if @options[:env] == 'dev'
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
