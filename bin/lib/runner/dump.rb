module Runner
  class Dump < Base
    def ip_address
      'WEB_IP'
    end

    def args
      "--tags #{@tags} -e env=#{@env}"
    end

    def playbook
      'database_cmd.yml'
    end
  end
end
