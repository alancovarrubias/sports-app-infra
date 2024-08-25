module Runner
  def self.run(options)
    cmd = get_runner(options).new(options).run
    run_command(cmd)
  end

  def self.run_command(cmd)
    system(cmd)
  end

  def self.get_runner(options)
    case options[:command]
    when 'apply', 'destroy'
      Terraform
    when 'run'
      const_get(options[:module].capitalize)
    end
  end
end
