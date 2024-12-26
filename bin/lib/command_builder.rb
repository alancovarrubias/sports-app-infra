module CommandBuilder
  def self.run(options)
    case options[:command]
    when 'apply', 'destroy'
      Terraform.new(options).run
    when 'run'
      Runner.const_get(options[:module].capitalize).new(options).run
    end
  end
end
