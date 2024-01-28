cd ansible
ansible-playbook --vault-password-file ~/.vault_pass.txt --inventory $ANSIBLE_IP, -e target_host_ip=$ANSIBLE_IP --private-key ~/.ssh/id_rsa --user root --tags ${1:-all} setup_ansible.yml