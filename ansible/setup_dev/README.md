# setup_dev

Sets up the sports-app on a single droplet running Docker Compose: logs into ECR, clones the app repo, sets up a local SSH tunnel (dev only), renders nginx/Docker Compose/cert config from templates, and brings the stack up with `docker-compose`.

**Note on its tags**: several tasks here also carry `stage`/`prod` tags (`login_ecr.yml`, `setup_git_repo.yml`, `start_server.yml`), suggesting this role once served stage/prod too. Neither `setup_stage.yml` nor `setup_prod.yml` reference this role today — they use `setup_app` (a Kubernetes deployment, not Docker Compose on a droplet) instead. These tags currently go unexercised; likely a leftover from the same pre-Kubernetes single-droplet architecture as `legacy_stage`/`legacy_prod` (deleted in ticket 004) and `setup_worker`/`setup_ansible` (see their READMEs).

## Variables

- `repo_name` — the app repo to clone.
- `user_name` — SSH/deploy user.
- `aws_region`, `ecr_repo_url` — for the ECR login step.
- `env` — written into `.bashrc` and used by several templates.

## Used by

`setup_dev.yml`, tag `dev`, invoked by `Runners::Dev` (`-c apply`/`-c run`).
