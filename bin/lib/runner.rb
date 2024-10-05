module Runner
  def self.run(options)
    get_runner(options).new(options).run
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
