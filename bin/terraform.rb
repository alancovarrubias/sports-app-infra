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

  def path
    case @env
    when 'prod'
      'ansible_jenkins'
    when 'dev'
      'sports_app_dev'
    end
  end

  def run
    if @command == 'apply'
      run_command('init')
      run_command('apply --auto-approve')
    elsif @command == 'destroy'
      run_command('destroy --auto-approve')
    end
  end

  def run_command(cmd)
    command = "terraform -chdir=\"$(pwd)/terraform/#{path}\" #{cmd}"
    puts command
    system(command)
  end
end

AnsibleRunner.new(options).run
