script_dir = File.dirname(File.expand_path(__dir__))
Dir.chdir(script_dir) do
  success = system('bundle install')
  system('sudo bundle install') unless success
end