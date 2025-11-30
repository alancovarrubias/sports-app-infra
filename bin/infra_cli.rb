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
    @options = {}
    OptionParser.new do |opts|
      OPTIONS.each do |key, args|
        opts.on(*args) do |cmd|
          @options[key] = cmd
        end
      end
    end.parse!
    @options[:tags] = @options[:tags].split(',') if @options[:tags]
    Dir.mkdir(OUTPUTS_DIR) unless Dir.exist?(OUTPUTS_DIR)
    @options.merge!(config_file: File.join(OUTPUTS_DIR, "#{@options[:module]}.json"))
  end

  def run
    run_command(command_runner)
    run_command(ANSIBLE_RUNNER) if command_runner == TERRAFORM_RUNNER && @options[:command] == APPLY_COMMAND
  end

  private

  def command_runner
    case @options[:command]
    when APPLY_COMMAND, DESTROY_COMMAND
      TERRAFORM_RUNNER
    when RUN_COMMAND
      ANSIBLE_RUNNER
    end
  end

  def run_command(runner)
    Dir.chdir(runner) do
      Object.const_get(runner.capitalize).run(@options) do |command|
        puts command
        system(command)
      end
    end
  end
end

InfraCLI.new.run
