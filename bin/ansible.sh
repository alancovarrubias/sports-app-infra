cd ansible
ansible-playbook --inventory $ANSIBLE_IP, --extra-vars @extra_vars.yml --skip-tags plugins --tags ${1:-all} setup_ansible.yml