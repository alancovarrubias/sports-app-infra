class BaseRunner
  def initialize(options)
    @env = options[:env]
    @args = options[:args]
    @inventory = options[:inventory]
  end

  def inventory
    @inventory || ENV[ip_address]
  end

  def vars
    '--extra-vars @extra_vars.yml'
  end

  def args
    ''
  end

  def run
    system("cd ansible && #{ansible_command}")
  end

  def ansible_command
    "ansible-playbook --inventory #{inventory}, #{vars} --skip-tags skip #{args} #{playbook}"
  end
end

class JenkinsRunner < BaseRunner
  def ip_address
    'JENKINS_IP'
  end

  def playbook
    'setup_jenkins.yml'
  end
end

class AnsibleRunner < BaseRunner
  def ip_address
    'ANSIBLE_IP'
  end

  def playbook
    'setup_ansible.yml'
  end
end

class WebRunner < BaseRunner
  def ip_address
    'WEB_IP'
  end

  def playbook
    'setup_web.yml'
  end

  def args
    "-t setup,#{@env} -e env=#{@env}"
  end
end

class WorkerRunner < BaseRunner
  def ip_address
    'WORKER_IP'
  end

  def playbook
    'setup_worker.yml'
  end

  def args
    @args || "-e web_ip=#{ENV['WEB_IP']}"
  end
end
