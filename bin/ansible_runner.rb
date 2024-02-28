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
    'web' => {
      playbook: 'setup_web.yml',
      ip_address: 'WEB_IP'
    },
    'worker' => {
      playbook: 'setup_worker.yml',
      ip_address: 'WORKER_IP'
    }
  }
  def initialize(options)
    module_data = MODULE_DATA[options[:module]]
    env = options[:env]
    @playbook = module_data[:playbook]
    @ip_address = options[:inventory] || ENV[module_data[:ip_address]]
    @vars = '--extra-vars @extra_vars.yml'
    @vars += " -t setup,#{env} -e env=#{env}" if options[:module] == 'web'
    return unless options[:module] == 'worker'

    @vars += if options[:args]
               " #{options[:args]}"
             else
               " -e web_ip=#{ENV['WEB_IP']}"
             end
  end

  def run
    system("cd ansible && ansible-playbook #{ansible_args}")
  end

  def ansible_args
    "--inventory #{@ip_address}, #{@vars} --skip-tags skip #{@tags} #{@playbook}"
  end
end
