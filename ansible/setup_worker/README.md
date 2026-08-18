# setup_worker

Sets up a background-job worker droplet: clones the app repo, logs into ECR, and starts the worker's Docker Compose stack (after waiting for the web droplet's Redis to be reachable).

**Likely dead**: this targets the pre-Kubernetes single-droplet architecture — the same one `legacy_stage`/`legacy_prod` (deleted in ticket 004) and the Jenkinsfile's stale `-i $WORKER_IP -m worker -e $ENV` call belong to. No current `Runners` class invokes `setup_worker.yml`, and the Terraform stacks that would have provisioned this droplet no longer exist. Flagged as a candidate for the same triage ticket 004 gave `legacy_stage`/`legacy_prod` — see the map's newly-added ticket for this.

## Variables

- `repo_name`, `user_name` — repo to clone, deploy user.
- `aws_region`, `ecr_repo_url` — for the ECR login step.
- `web_ip` — the web droplet's IP, to wait on its Redis before starting.

## Used by

`setup_worker.yml`, tag `setup`. Not invoked by the Ruby CLI.
