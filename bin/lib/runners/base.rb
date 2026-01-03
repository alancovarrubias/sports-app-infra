module Runners
  class Base
    include Constants
    def initialize(options)
      @options = options
      @options[:tags] = @options[:tags]&.split(',')
      @options[:output_file] = generate_output_file
      @terraform_command = Commands::Terraform.new(@options)
      @ansible_command = Commands::Ansible.new
    end

    def run_ansible(options)
      ansible_command = @ansible_command.build(options)
      run_commands(ANSIBLE, ansible_command)
    end

    def run_terraform(*commands)
      terraform_commands = commands.map { |command| @terraform_command.build(command) }
      run_commands(TERRAFORM, terraform_commands)

      reload_outputs!
    end

    protected

    def outputs
      @outputs ||= load_outputs
    end

    private

    def run_commands(dir_name, commands)
      dir = File.join(InfraCLI::ROOT_DIR, dir_name)
      Dir.chdir(dir) do
        Array(commands).each do |command|
          puts command
          system(command)
        end
      end
    end

    def reload_outputs!
      @outputs = load_outputs
    end

    def generate_output_file
      Dir.mkdir(OUTPUTS_DIR) unless Dir.exist?(OUTPUTS_DIR)
      File.join(OUTPUTS_DIR, "#{@options[:module]}.json")
    end

    def load_outputs
      return {} unless File.exist?(@options[:output_file])

      JSON.parse(File.read(@options[:output_file]))
    end
  end
end
