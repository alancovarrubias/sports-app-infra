# setup_docker

Installs Docker and Docker Compose on a fresh Ubuntu droplet: adds the Docker apt repo and GPG key, installs `docker-ce`/`docker-compose`, adds `user_name` to the `docker` group, and opens up `docker.sock` permissions so that user can run Docker without `sudo`.

## Variables

- `user_name` — the user to add to the `docker` group. No default; must be supplied by the caller.

## Used by

Every droplet-based playbook, right after `setup_server`: `setup_dev.yml`, `setup_jenkins.yml`, `setup_mercor.yml`. Not used by `setup_stage.yml`/`setup_prod.yml` (Kubernetes, not a droplet with Docker installed directly on it).
