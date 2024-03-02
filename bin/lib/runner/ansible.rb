module Runner
  class Ansible < Base
    def ip_address
      'ANSIBLE_IP'
    end

    def playbook
      'setup_ansible.yml'
    end
  end
end
