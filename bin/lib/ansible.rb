require 'json'
module Ansible
  module_function

  OUTPUTS_DIR = '../bin/outputs'.freeze
  def run(options)
    @options = options
    @config = send(@options[:module])
    @output = read_output
    @inventory = @output['web_ip']['value'] unless @output['web_ip'].nil?
    @tags = @options[:tags] || @config[:tags]
    yield build_command
  end

  def build_command
    command = ['ansible-playbook', '-e @extra_vars.yml', '-e @custom_vars.yml']
    command << "--inventory #{@inventory},"
    command << "--tags #{@tags.join(',')}" if @tags
    command << "-e env=#{@options[:module]}"
    command << @config[:playbook]
    command.join(' ')
  end

  def read_output
    config_file = "#{OUTPUTS_DIR}/#{@options[:module]}.json"
    File.exist?(config_file) ? JSON.parse(File.read(config_file)) : {}
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
