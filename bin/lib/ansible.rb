module Ansible
    module_function

    def run(options)
      @options = options
      @config = send(@options[:module])
      @tags = (@options[:tags] || []).concat(@config[:tags] || [])
      @vars = (@config[:vars] || {}).merge(env: @options[:env])
      @inventory = @options[:inventory] || ENV[@config[:ip_env]]
      yield build_command
    end

    def build_command
      command = ['ansible-playbook', '-e @extra_vars.yml', '-e @custom_vars.yml', '--skip-tags skip']
      command << "--inventory #{@inventory},"
      command << "--tags #{@tags.join(',')}" unless @tags.empty?
      @vars.each do |key, value|
        command << "-e #{key}=#{value}"
      end
      command << @config[:playbook]
      command.join(' ')
    end

    def ansible
      {
        playbook: 'setup_ansible.yml',
        tags: %w[setup server],
        ip_env: 'ANSIBLE_IP',
        vars: {
          do_token: @options[:token],
          web_ip: @options[:web_ip],
          worker_ip: @options[:worker_ip]
        }
      }
    end

    def jenkins
      {
        playbook: 'setup_jenkins.yml',
        ip_env: 'JENKINS_IP'
      }
    end

    def dump
      {
        playbook: 'database_cmd.yml',
        ip_env: 'WEB_IP'
      }
    end

    def web
      {
        playbook: 'setup_web.yml',
        tags: ['setup', 'create', 'client', @options[:env]],
        ip_env: 'WEB_IP'
      }
    end

    def worker
      {
        playbook: "-e web_ip=#{@options[:web_ip]} setup_worker.yml",
        tags: %w[setup client],
        ip_env: 'WORKER_IP',
        vars: {
          web_ip: @options[:web_ip]
        }
      }
    end
end
