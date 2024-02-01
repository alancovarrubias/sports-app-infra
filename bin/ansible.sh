cd ansible
ansible-playbook --inventory $ANSIBLE_IP, --tags ${1:-all} setup_ansible.yml