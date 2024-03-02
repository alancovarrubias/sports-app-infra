module Runner
  class Worker < Base
    def ip_address
      'WORKER_IP'
    end

    def playbook
      'setup_worker.yml'
    end

    def args
      @args || "-e web_ip=#{ENV['WEB_IP']}"
    end
  end
end
