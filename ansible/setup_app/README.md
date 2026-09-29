# setup_app

Deploys the sports-app to a Kubernetes cluster: logs into the DigitalOcean Container Registry, tags and pushes the app's Docker images (`registry` tag), then renders and applies every Kubernetes manifest under `templates/k8s/` — Deployments, Services, Secrets, the client Ingress, and (prod only) the cert-manager `ClusterIssuer` (`kube` tag) — waits for the database pods, runs `rake db:migrate` per service, and (stage only) updates local `/etc/hosts` so `sports-app.test` resolves to the ingress IP.

This role is what `terraform/{stage,prod}/modules/{infra,registry,ingress}` — the deduplicated Terraform modules from ticket 003 — get configured *by*, once they exist. It's environment-agnostic by design: `stage`/`prod`-specific behavior (the `ClusterIssuer`, the `/etc/hosts` hack, TLS on the Ingress) is driven by Jinja `{% if env == 'prod' %}`/`{% if env == 'stage' %}` conditionals in the templates, not by two copies of the role — this is the role `setup_stage`/`setup_prod` were merged into (commit `b24a84b`, "Remove duplicate logic between stage and prod").

## Variables

Supplied by `Runners::Cluster#ansible_variables` (`bin/lib/runners/cluster.rb`): `secret_key_base`, `cache_url`, `mongo_url`, `database_url`, `auth_database_url`, `football_database_url`, `registry_name`, `kubeconfig`, plus (`stage` only) `domain_name`, `local_image_tag`. `env` is passed separately as `Commands::Ansible#build`'s own `env:` argument, not part of this hash. `registry_containers` defaults to the static list in `extra_vars.yml` (`client`, `server`, `auth`, `football`, `crawler`) but is overridden here — to a single-element or empty list — when the CLI's `-s`/`--service` flag scopes a `-c registry` run to one service (see the root README's "Redeploying a single service").

## Used by

`setup_stage.yml` and `setup_prod.yml`, invoked by `Runners::Stage`/`Runners::Prod` (`-c registry`/`-c kube`/`-c apply`, etc. — see `bin/lib/runners/cluster.rb`).
