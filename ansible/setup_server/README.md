# setup_server

Baseline hardening for a fresh droplet: waits for SSH to come up, creates the non-root `user_name` user with passwordless sudo, and copies the root user's `authorized_keys` over so the new user can log in the same way root did.

## Variables

- `user_name` — the non-root user to create. No default; must be supplied by the caller.

## Used by

Every droplet-based playbook runs this first, before anything role-specific: `setup_dev.yml`, `setup_jenkins.yml`, `setup_mercor.yml`, `setup_worker.yml`, `setup_ansible.yml`. Not used by `setup_stage.yml`/`setup_prod.yml` — those target a Kubernetes cluster, not a droplet.
