require 'json'
class Ansible
  def initialize(options)
    @options = options
    @output = File.exist?(@options[:output_file]) ? JSON.parse(File.read(@options[:output_file])) : {}
    @module_config = send(@options[:module])
    @variables = @module_config[:variables] || {}
    @inventory = @output['web_ip']['value'] unless @output['web_ip'].nil?
    @tags = @options[:tags] || @module_config[:tags]
  end

  def run
    yield build_command
  end

  private

  def build_command
    command = ['ansible-playbook', '-e @extra_vars.yml', '-e @custom_vars.yml']
    command << "--inventory #{@inventory},"
    command << "--tags #{@tags.join(',')}" if @tags
    command << "-e env=#{@options[:module]}"
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
