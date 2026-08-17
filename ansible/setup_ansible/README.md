# setup_ansible

Sets up a droplet as an Ansible control node: installs Ansible/pip/AWS CLI, copies AWS credentials, an SSH private key, and the vault password file, then deploys `monitor_website.py` as a systemd service (a small uptime-check script that emails on failure, per `email_address`/`email_password`).

**Likely dead**: part of the same pre-Kubernetes single-droplet architecture as `setup_worker` and the deleted `legacy_stage`/`legacy_prod` Terraform stacks (matches the Jenkinsfile's stale `ANSIBLE_IP`/`-m ansible` references). No current `Runners` class invokes `setup_ansible.yml`. Flagged for the same triage ticket as `setup_worker`.

## Variables

- `email_address`, `email_password` — for the monitor service's failure alerts.
- `user_name` — deploy user.

## Used by

`setup_ansible.yml`, tag `setup`. Not invoked by the Ruby CLI.
