cd ansible
ansible-playbook --inventory $DEV_IP, --extra-vars @extra_vars.yml --tags ${1:-all} setup_sports_app_dev.yml