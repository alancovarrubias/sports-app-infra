module Runner
  class Web < Base
    def ip_address
      'WEB_IP'
    end

    def playbook
      'setup_web.yml'
    end

    def args
      "--tags setup,create,#{@env},client -e env=#{@env}"
    end
  end
end
