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

    def start
      case @options[:command]
      when APPLY_COMMAND
        apply
      when DESTROY_COMMAND
        destroy
      when RUN_COMMAND
        run
      end
    end

    def outputs
      @outputs ||= load_outputs
    end

    def run_ansible(commands)
      run_commands(ANSIBLE_WORKING_DIR, commands)
    end

    def run_terraform(commands)
      run_commands(TERRAFORM_WORKING_DIR, commands)

      reload_outputs!
    end

    private

    def run_commands(dir, commands)
      Dir.chdir(dir) do
        Array(commands).each do |command|
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
