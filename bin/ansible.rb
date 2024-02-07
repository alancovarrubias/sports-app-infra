#!/usr/bin/env ruby

require 'optparse'

options = {
  command: ARGV[0]
}
OptionParser.new do |opts|
  opts.banner = 'Usage: example_cli.rb [options]'

  opts.on('-e', '--env ENV', 'Specify env') do |env|
    options[:env] = env
  end
end.parse!

class AnsibleRunner
  def initialize(options)
    @env = options[:env]
    @command = options[:command]
  end

  def tags
    if @command == 'jenkins'
      '--skip-tags plugins'
    elsif @command == 'ansible'
      ''
    elsif @command == 'dev'
      ''
    end
  end

  def playbook
    if @command == 'jenkins'
      'setup_jenkins.yml'
    elsif @command == 'ansible'
      'setup_ansible.yml'
    elsif @command == 'dev'
      'setup_sports_app_dev.yml'
    end
  end

  def ip
    if @command == 'jenkins'
      ENV['JENKINS_IP']
    elsif @command == 'ansible'
      ENV['ANSIBLE_IP']
    elsif @command == 'dev'
      ENV['DEV_IP']
    end
  end

  def run_command(cmd)
    puts cmd
    system("ansible-playbook --inventory #{ip}, --extra-vars @extra_vars.yml #{tags} #{playbook}")
  end
end

AnsibleRunner.new(options).run
