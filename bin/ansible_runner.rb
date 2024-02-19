class AnsibleRunner
  attr_reader :skip_tags, :playbook, :ip_address, :vars, :tags

  MODULE_DATA = {
    'jenkins' => {
      playbook: 'setup_jenkins.yml',
      ip_address: 'JENKINS_IP'
    },
    'ansible' => {
      playbook: 'setup_ansible.yml',
      ip_address: 'ANSIBLE_IP'
    },
    'dev' => {
      playbook: 'setup_sports_app_dev.yml',
      ip_address: 'DEV_IP'
    },
    'worker' => {
      playbook: 'setup_sports_app_worker.yml',
      ip_address: 'WORKER_IP'
    }
  }
  def initialize(options)
    module_data = MODULE_DATA[options[:module]]
    @playbook = module_data[:playbook]
    @ip_address = ENV[module_data[:ip_address]]
    @vars = '--extra-vars @extra_vars.yml'
    @vars += " -e web_ip=#{ENV['DEV_IP']}" if options[:module] == 'worker'
    @tags = "--tags #{options[:tags]}" if options[:tags]
  end

  def run
    system("cd ansible && ansible-playbook #{ansible_args}")
  end

  def ansible_args
    "--inventory #{@ip_address}, #{@vars} --skip-tags skip #{@tags} #{@playbook}"
  end
end
