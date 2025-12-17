module Commands
  class Base
    APPLY_COMMAND = 'apply'.freeze
    DESTROY_COMMAND = 'destroy'.freeze
    RUN_COMMAND = 'run'.freeze
    OUTPUTS_DIR = File.join(InfraCLI::ROOT_DIR, 'bin/outputs')
    def initialize(options)
      options[:tags] = options[:tags].split(',') if options[:tags]
      Dir.mkdir(OUTPUTS_DIR) unless Dir.exist?(OUTPUTS_DIR)
      options[:output_file] = File.join(OUTPUTS_DIR, "#{options[:module]}.json")
      @command = options[:command]
      @terraform_runner = Terraform.new(options)
      @ansible_runner = Ansible.new(options)
    end

    def start
      case @command
      when APPLY_COMMAND
        apply
      when DESTROY_COMMAND
        destroy
      when RUN_COMMAND
        run
      end
    end
  end
end
