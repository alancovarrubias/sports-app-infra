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

  def run
    options = parse_options
    command = Runners.const_get(options[:env].capitalize).new(options)
    command.send(options[:command])
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
