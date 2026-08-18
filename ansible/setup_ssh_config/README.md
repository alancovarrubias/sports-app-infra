# setup_ssh_config

Runs on the *local* machine (every task is `delegate_to: localhost`), not the remote droplet: writes an SSH config snippet for the droplet under `~/.ssh/<server_name>` and makes sure `~/.ssh/config` `Include`s it, so `ssh <server_name>` works without remembering the droplet's IP.

## Variables

- `server_name` — the `Host` alias to write (e.g. `dev`, `jenkins`, `mercor`, `worker`, `ansible`). No default; must be supplied by the caller.
- `inventory_hostname` — supplied by Ansible's inventory (the droplet's IP), used as the `HostName`.
- `user_name` — the SSH user.
- `env_var` — passed by several callers (e.g. `JENKINS_IP`, `MERCOR_IP`, `WORKER_IP`, `ANSIBLE_IP`) but not currently referenced anywhere in this role's tasks or its `ssh_config` template — dead input as of this writing.

## Used by

Every droplet-based playbook, right after `setup_server`/`setup_docker`, each with its own `server_name`: `setup_dev.yml` (`dev`), `setup_jenkins.yml` (`jenkins`), `setup_mercor.yml` (`mercor`), `setup_worker.yml` (`worker`), `setup_ansible.yml` (`ansible`).
