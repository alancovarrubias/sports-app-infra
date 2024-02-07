#!/usr/bin/env ruby

require 'optparse'

options = {
  command: ARGV[0]
}
@module_map = {
  'dev': 'sports_app_dev'
}
OptionParser.new do |opts|
  opts.banner = 'Usage: example_cli.rb [options]'

  opts.on('-m', '--module MODULE', 'Specify module') do |mod|
    options[:module] = @module_map[mod] || mod
  end
end.parse!

class AnsibleRunner
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

  def common_args
    '-var-file=../terraform.tfvars --auto-approve'
  end

  def run_command(cmd)
    system("terraform -chdir=\"$(pwd)/terraform/#{@module}\" #{cmd}")
  end
end

AnsibleRunner.new(options).run
