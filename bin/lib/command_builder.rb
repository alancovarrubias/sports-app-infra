class CommandBuilder
  def initialize(inventory:, tags:, playbook:, args:)
    @inventory = inventory
    @tags = tags
    @playbook = playbook
    @args = args
  end

  def ansible
    ['ansible-playbook', inventory, vars, skip_tags, tags, args, @playbook].join(' ')
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
