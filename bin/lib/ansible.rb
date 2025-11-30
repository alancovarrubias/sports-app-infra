require 'json'
class Ansible
  def initialize(options)
    @options = options
    @module_config = send(@options[:module])
    @output = File.exist?(@options[:output_file]) ? JSON.parse(File.read(@options[:output_file])) : {}
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
    command << @module_config[:playbook]
    command.join(' ')
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
      playbook: 'setup_prod.yml'
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
