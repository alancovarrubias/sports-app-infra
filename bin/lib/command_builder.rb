class CommandBuilder
  TERRAFORM_DIR = '$(pwd)/terraform'.freeze
  def initialize(options)
    @playbook = options[:playbook]
    @command = options[:command]
    @module = options[:module]
    @inventory = options[:inventory]
    @tags = options[:tags]
    @args = options[:args] || {}
  end

  def terraform
    ['init', "#{@command} -var-file=#{TERRAFORM_DIR}/terraform.tfvars --auto-approve"].map do |cmd|
      build_terraform(cmd)
    end
  end

  def build_terraform(cmd)
    "terraform -chdir=#{TERRAFORM_DIR}/#{@module} #{cmd}"
  end

  def ansible
    commands = []
    commands << 'cd ansible && ansible-playbook'
    commands << inventory
    commands << vars
    commands << tags if @tags
    commands << args unless @args.empty?
    commands << @playbook
    commands.join(' ')
  end

  def args
    @args.map { |key, value| "-e #{key}=#{value}" }.join(' ')
  end

  def inventory
    "--inventory #{@inventory},"
  end

  def vars
    '--extra-vars @extra_vars.yml'
  end

  def skip_tags
    '--skip-tags skip'
  end

  def tags
    "--tags #{@tags}"
  end
end
