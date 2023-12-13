cd ansible
ansible-playbook --inventory $DROPLET_IP, -e target_host_ip=$DROPLET_IP --private-key /Users/alancovarrubias/.ssh/id_rsa --user root setup_server.yml