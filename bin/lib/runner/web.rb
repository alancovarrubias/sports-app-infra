module Runner
  class Web < Base
    def ip_address
      'WEB_IP'
    end

    def playbook
      'setup_web.yml'
    end

    def args
      "-t setup,#{@env} -e env=#{@env}"
    end
  end
end
