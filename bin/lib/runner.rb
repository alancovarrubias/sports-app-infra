class Runner
  def self.run(options)
    new(options).run
  end

  def initialize(options)
    @options = options
  end

  def run
    case @command
    when 'apply', 'destroy'
      CommandBuilder.new(@options).terraform do |cmd|
        run_command(cmd)
      end
    when 'run'
      cmd = send(@options[:module])
      run_command(cmd)
    end
  end

  def run_command(cmd)
    system(cmd)
  end

  def build_command; end

  def dump
    CommandBuilder.new(playbook: 'database_cmd.yml', inventory: ENV['WEB_IP'], tags: @options[:tags]).ansible
  end

  def ansible
    CommandBuilder.new(playbook: 'setup_ansible.yml',
                       inventory: ENV['ANSIBLE_IP'],
                       args: { do_token: @options[:token], web_ip: @options[:web_ip] }).ansible
  end

  def jenkins
    CommandBuilder.new(playbook: 'setup_jenkins.yml', inventory: ENV['JENKINS_IP']).ansible
  end

  def web
    CommandBuilder.new(playbook: 'setup_web.yml', inventory: ENV['WEB_IP'], tags: "setup,#{@options[:env]}",
                       args: { env: @options[:env] }).ansible
  end

  def worker
    CommandBuilder.new(playbook: 'setup_worker.yml', inventory: ENV['WORKER_IP'],
                       args: { web_ip: @options[:web_ip], env: @options[:env] }).ansible
  end
end
