#!/usr/bin/env ruby
require 'optparse'
require_relative 'config/zeitwerk'
require_relative 'config/bundler'

module InfraCLI
  module_function

  OPTIONS = {
    command: ['-c', '--command COMMAND', 'Specify command'],
    env: ['-e', '--env ENV', 'Specify environment'],
    tags: ['--tags TAGS', 'Specify tags'],
    database: ['-d', '--database DATABASE', 'Specify database']
  }.freeze

  RUNNERS = {
    'stage' => Runners::Cluster,
    'prod' => Runners::Cluster,
    'dev' => Runners::Droplet,
    'mercor' => Runners::Droplet
  }.freeze

  def run
    options = parse_options
    runner_class = RUNNERS.fetch(options[:env]) do
      abort("Unknown environment '#{options[:env]}' -- expected one of #{RUNNERS.keys.join(', ')}")
    end

    runner_class.new(options).send(options[:command])
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

if $PROGRAM_NAME == __FILE__
  Bootstrap.ensure_gems_installed!
  InfraCLI.run
end
