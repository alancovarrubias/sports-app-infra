module Runner
  class Base
    def initialize(options)
      @env = options[:env]
      @inventory = options[:inventory]
      @token = options[:token]
      @web_ip = options[:web_ip]
      @tags = options[:tags]
    end

    def inventory
      @inventory || ENV[ip_address]
    end

    def vars
      '--extra-vars @extra_vars.yml'
    end

    def args
      ''
    end

    def run
      "cd ansible && #{ansible_command}"
    end

    def ansible_command
      "ansible-playbook --inventory #{inventory}, #{vars} --skip-tags skip #{args} #{playbook}"
    end
  end
end
