cd ansible
ansible-playbook --inventory $JENKINS_IP, -e ansible_ip=$ANSIBLE_IP --tags ${1:-all} --skip-tags plugins setup_jenkins.yml