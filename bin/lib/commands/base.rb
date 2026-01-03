module Commands
  class Base
    include Constants
    def initialize(options)
      @options = options
      @options[:tags] = @options[:tags]&.split(',')
      @options[:output_file] = generate_output_file
      @terraform_runner = Runners::Terraform.new(@options)
      @ansible_runner = Runners::Ansible.new
    end

    def outputs
      @outputs ||= load_outputs
    end

    def run_ansible(options)
      commands = @ansible_runner.command(options)
      run_commands(ANSIBLE, commands)
    end

    def run_terraform(*commands)
      run_commands(TERRAFORM, commands)

      reload_outputs!
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
