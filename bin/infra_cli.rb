#!/usr/bin/env ruby
require 'optparse'
require_relative 'config/zeitwerk'
require_relative 'config/bundler'

class InfraCLI
  ANSIBLE_RUNNER = 'ansible'.freeze
  TERRAFORM_RUNNER = 'terraform'.freeze
  APPLY_COMMAND = 'apply'.freeze
  DESTROY_COMMAND = 'destroy'.freeze
  RUN_COMMAND = 'run'.freeze
  ROOT_DIR = File.expand_path('..', __dir__)
  OUTPUTS_DIR = File.join(ROOT_DIR, 'bin/outputs')
  OPTIONS = {
    command: ['-c', '--command COMMAND', 'Specify command'],
    module: ['-m', '--module MODULE', 'Specify module'],
    tags: ['--tags TAGS', 'Specify tags']
  }.freeze

  def initialize
    options = parse_options
    @command = options[:command]
    @module = options[:module]
    options[:tags] = options[:tags].split(',') if options[:tags]
    Dir.mkdir(OUTPUTS_DIR) unless Dir.exist?(OUTPUTS_DIR)
    options[:output_file] = File.join(OUTPUTS_DIR, "#{options[:module]}.json")
    @terraform_runner = Terraform.new(options)
    @ansible_runner = Ansible.new(options)
  end

  def run
    @module == 'prod' ? run_prod_commands : run_commands
  end

  private

  def run_prod_commands
    case @command
    when APPLY_COMMAND
      @terraform_runner.run_prod_infra_commands
      @ansible_runner.run
      @terraform_runner.run_prod_kube_commands
    when DESTROY_COMMAND
      @terraform_runner.run_prod_destroy_commands
    end
  end

  def run_commands
    case @command
    when APPLY_COMMAND
      @terraform_runner.run
      @ansible_runner.run
    when DESTROY_COMMAND
      @terraform_runner.run
    when RUN_COMMAND
      @ansible_runner.run
    end
  end

  def parse_options
    options = {}
    OptionParser.new do |opts|
      OPTIONS.each do |key, args|
        opts.on(*args) do |cmd|
          options[key] = cmd
        end
      end
    end.parse!
    options
  end
end

InfraCLI.new.run
