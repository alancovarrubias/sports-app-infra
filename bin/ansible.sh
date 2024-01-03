cd ansible
ansible-playbook --vault-password-file ~/.vault_pass.txt --inventory $DROPLET_IP, -e target_host_ip=$DROPLET_IP --private-key ~/.ssh/id_rsa --user root setup_server.yml