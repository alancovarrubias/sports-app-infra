module Runner
  class Jenkins < Base
    def ip_address
      'JENKINS_IP'
    end

    def playbook
      'setup_jenkins.yml'
    end
  end
end
