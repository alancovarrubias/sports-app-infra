module Runner
  class Ansible < Base
    def ip_address
      'ANSIBLE_IP'
    end

    def playbook
      'setup_ansible.yml'
    end

    def args
      "-e do_token=#{@token} -e web_ip=#{@web_ip} -e worker_ip=#{@worker_ip} --tags setup,server"
    end
  end
end
