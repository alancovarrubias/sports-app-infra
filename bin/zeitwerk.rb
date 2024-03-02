# zeitwerk.rb

require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path('lib', __dir__))
loader.setup
