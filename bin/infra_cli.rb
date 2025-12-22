#!/usr/bin/env ruby
require 'optparse'
require_relative 'config/zeitwerk'
require_relative 'config/bundler'

module InfraCLI
  module_function

  ROOT_DIR = File.expand_path('..', __dir__)
  OPTIONS = {
    command: ['-c', '--command COMMAND', 'Specify command'],
    module: ['-m', '--module MODULE', 'Specify module'],
    tags: ['--tags TAGS', 'Specify tags']
  }.freeze

  def run
    options = parse_options
    command = Commands.const_get(options[:module].capitalize).new(options)
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

InfraCLI.run
