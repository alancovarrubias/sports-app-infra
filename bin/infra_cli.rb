#!/usr/bin/env ruby
require 'optparse'
require_relative 'config/zeitwerk'
require_relative 'config/bundler'

options = {}
COMMANDS = [
  [:command, '-c', '--command COMMAND', 'Specify command'],
  [:env, '-e', '--env ENV', 'Specify env'],
  [:module, '-m', '--module MODULE', 'Specify module'],
  [:tags, '--tags TAGS', 'Specify tags'],
  [:kube_id, '-k', '--kube_id KUBE_ID', 'Specify kube cluster id'],
  [:token, '--token TOKEN', 'Specify TOKEN'],
  [:inventory, '-i', '--inventory INVENTORY', 'Specify inventory'],
  [:web_ip, '--web_ip WEB_IP', 'Specify web ip'],
  [:worker_ip, '--worker_ip WORKER_IP', 'Specify worker ip'],
  [:domain_name, '-d', '--domain DOMAIN_NAME', 'Specify web domain name']
].freeze
OptionParser.new do |opts|
  opts.banner = 'Usage: ansible.rb [options]'

  COMMANDS.each do |command|
    key, *args = command
    opts.on(*args) do |cmd|
      options[key] = cmd
    end
  end
end.parse!

options[:kube_id] ||= ENV['KUBE_ID']
options[:web_ip] ||= ENV['WEB_IP']
options[:worker_ip] ||= ENV['WORKER_IP']
options[:token] ||= ENV['DO_TOKEN']
options[:tags] = options[:tags].split(',') if options[:tags]

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
