cd ansible
ansible-playbook --inventory $JENKINS_IP, -e ansible_ip=$ANSIBLE_IP --extra-vars @extra_vars.yml --skip-tags plugins --tags ${1:-all} --skip-tags plugins setup_jenkins.yml