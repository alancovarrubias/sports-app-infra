require 'json'
module Ansible
  module_function

  def run(options)
    @options = options
    @env = options[:module]
    @config = send(@options[:module])
    unless @options[:module] == 'kube'
      output_contents = File.read("./outputs/#{options[:module]}.json")
      @inventory = JSON.parse(output_contents)['web_ip']['value']
    end
    @tags = @options[:tags] || @config[:tags]
    @vars = { env: @env }
    yield build_command
  end

  def build_command
    command = ['ansible-playbook', '-e @extra_vars.yml', '-e @custom_vars.yml']
    command << "--inventory #{@inventory},"
    command << "--tags #{@tags.join(',')}" if @tags&.any?
    @vars.each do |key, value|
      command << "-e #{key}=#{value}"
    end
    command << @config[:playbook]
    command.join(' ')
  end

  def dev
    {
      playbook: 'setup_dev.yml',
      tags: %w[setup server docker create client dev]
    }
  end

  def worker
    {
      playbook: 'setup_worker.yml',
      tags: %w[setup server docker client],
      ip_env: 'WORKER_IP',
      vars: {
        web_ip: @options[:web_ip]
      }
    }
  end

  def ansible
    {
      playbook: 'setup_ansible.yml',
      tags: %w[setup server docker server],
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
      playbook: 'database_cmd.yml'
    }
  end

  def kube
    {
      playbook: 'setup_kube.yml'
    }
  end

  def mercor
    {
      playbook: 'setup_mercor.yml',
      tags: %w[setup server docker mercor],
      ip_env: 'MERCOR_IP'
    }
  end
end
