#!/usr/bin/env ruby
require 'optparse'
require_relative 'config/zeitwerk'
require_relative 'config/bundler'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: ansible.rb [options]'

  opts.on('-c', '--command COMMAND', 'Specify command') do |cmd|
    options[:command] = cmd
  end

  opts.on('-e', '--env ENV', 'Specify env') do |env|
    options[:env] = env
  end

  opts.on('-m', '--module MODULE', 'Specify module') do |mod|
    options[:module] = mod
  end

  opts.on('--tags TAGS', 'Specify tags') do |tags|
    options[:tags] = tags.split(',')
  end

  opts.on('--token TOKEN', 'Specify TOKEN') do |token|
    options[:token] = token
  end

  opts.on('-i', '--inventory INVENTORY', 'Specify inventory') do |inventory|
    options[:inventory] = inventory
  end

  opts.on('--web_ip WEB_IP', 'Specify web ip') do |web_ip|
    options[:web_ip] = web_ip
  end

  opts.on('--worker_ip WORKER_IP', 'Specify worker ip') do |worker_ip|
    options[:worker_ip] = worker_ip
  end

  opts.on('-d', '--domain DOMAIN_NAME', 'Specify web domain name') do |domain_name|
    options[:domain_name] = domain_name
  end
end.parse!

options[:web_ip] ||= ENV['WEB_IP']
options[:worker_ip] ||= ENV['WORKER_IP']
options[:token] ||= ENV['DO_TOKEN']

def get_runner(command)
  case command
  when 'apply', 'destroy'
    'terraform'
  when 'run'
    'ansible'
  end
end

runner = get_runner(options[:command])
Dir.chdir(runner) do
  Object.const_get(runner.capitalize).run(options) do |command|
    puts command
    system(command)
  end
end
