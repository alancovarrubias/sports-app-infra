#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ansible.rb [options]'

  opts.on('-c', '--command COMMAND', 'Specify command') do |cmd|
    options[:command] = cmd
  end

  opts.on('-m', '--module MODULE', 'Specify module') do |mod|
    options[:module] = mod
  end

  opts.on('-t', '--tags TAGS', 'Specify tags') do |tags|
    options[:tags] = tags
  end
end.parse!

class AnsibleRunner
  def initialize(options)
    @command = options[:command]
    @tags = options[:tags]
    @module = options[:module]
  end

  def custom_tags
    "--tags #{@tags}" if @tags
  end

  def tags
    if @module == 'jenkins'
      '--skip-tags plugins'
    elsif @module == 'ansible'
      ''
    elsif @module == 'dev'
      ''
    end
  end

  def playbook
    if @module == 'jenkins'
      'setup_jenkins.yml'
    elsif @module == 'ansible'
      'setup_ansible.yml'
    elsif @module == 'dev'
      'setup_sports_app_dev.yml'
    end
  end

  def ip
    if @module == 'jenkins'
      ENV['JENKINS_IP']
    elsif @module == 'ansible'
      ENV['ANSIBLE_IP']
    elsif @module == 'dev'
      ENV['DEV_IP']
    end
  end

  def run
    system("cd ansible && ansible-playbook --inventory #{ip}, --extra-vars @extra_vars.yml #{custom_tags} #{tags} #{playbook}")
  end
end

class TerraformRunner
  def initialize(options)
    @module = options[:module]
    @command = options[:command]
  end

  def run
    if @command == 'apply'
      run_command('init')
      run_command("apply #{common_args}")
    elsif @command == 'destroy'
      run_command("destroy #{common_args}")
    end
  end

  def sub_dir
    @module == 'dev' ? 'sports_app_dev' : @module
  end

  def common_args
    '-var-file=../terraform.tfvars --auto-approve'
  end

  def run_command(cmd)
    tf_cmd = "terraform -chdir=\"$(pwd)/terraform/#{sub_dir}\" #{cmd}"
    system(tf_cmd)
  end
end

if options[:command] == 'run'
  AnsibleRunner.new(options).run
else
  TerraformRunner.new(options).run
end
