module Runner
  class Worker < Base
    def ip_address
      'WORKER_IP'
    end

    def playbook
      'setup_worker.yml'
    end

    def args
      "-e web_ip=#{@web_ip} -e env=#{@env}"
    end
  end
end
