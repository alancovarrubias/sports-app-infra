require 'json'
class Ansible
  WORKING_DIR = File.join(InfraCLI::ROOT_DIR, 'ansible')
  def initialize(options)
    @options = options
    @module = @options[:module]
    @output_file = @options[:output_file]
  end

  def run
    @output = File.exist?(@output_file) ? JSON.parse(File.read(@output_file)) : {}
    @inventory = @output['web_ip']['value'] if @output['web_ip']
    @module_config = send(@module)
    @variables = @module_config[:variables] || {}
    @tags = @options[:tags] || @module_config[:tags]
    Dir.chdir(WORKING_DIR) do
      system(command)
    end
  end

  private

  def command
    command = ['ansible-playbook', '-e @extra_vars.yml', '-e @custom_vars.yml']
    command << "--inventory #{@inventory},"
    command << "--tags #{@tags.join(',')}" if @tags
    command << "-e env=#{@module}"
    @variables.each do |key, value|
      command << "-e #{key}=#{value}"
    end
    command << @module_config[:playbook]
    command.join(' ')
  end

  def secret_key_base
    `ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'`.chomp
  end

  def dev
    {
      playbook: 'setup_dev.yml',
      tags: %w[setup server docker create client dev]
    }
  end

  def stage
    {
      playbook: 'setup_stage.yml'
    }
  end

  def prod
    {
      playbook: 'setup_prod.yml',
      variables: {
        secret_key_base: secret_key_base,
        cache_url: @output['cache_uri']['value'],
        database_url: @output['database_uri']['value'],
        cluster_id: @output['k8s_cluster_id']['value'],
        registry_name: @output['registry_name']['value']
      }
    }
  end

  def worker
    {
      playbook: 'setup_worker.yml',
      tags: %w[setup server docker client]
    }
  end

  def ansible
    {
      playbook: 'setup_ansible.yml',
      tags: %w[setup server docker server]
    }
  end

  def jenkins
    {
      playbook: 'setup_jenkins.yml'
    }
  end

  def dump
    {
      playbook: 'database_cmd.yml'
    }
  end

  def mercor
    {
      playbook: 'setup_mercor.yml',
      tags: %w[setup server docker mercor]
    }
  end
end
