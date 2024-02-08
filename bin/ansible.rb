#!/usr/bin/env ruby

require 'optparse'

options = {
  command: ARGV[0]
}
OptionParser.new do |opts|
  opts.banner = 'Usage: ansible.rb [options]'

  opts.on('-m', '--module MODULE', 'Specify module') do |mod|
    options[:mod] = mod
  end

  opts.on('-t', '--tags TAGS', 'Specify tags') do |tags|
    options[:tags] = tags
  end
end.parse!

class AnsibleRunner
  def initialize(options)
    @env = options[:env]
    @command = options[:command]
    @tags = options[:tags]
  end

  def custom_tags
    "--tags #{@tags}" if @tags
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

  def run
    system("cd ansible && ansible-playbook --inventory #{ip}, --extra-vars @extra_vars.yml #{custom_tags} #{tags} #{playbook}")
  end
end

AnsibleRunner.new(options).run
