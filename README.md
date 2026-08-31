# sports-app-infra

Infrastructure-as-code for deploying and operating the sports-app across four environments — `dev`, `stage`, `prod`, `mercor` — using Terraform, Ansible, and a small Ruby CLI that orchestrates both.

## Vocabulary

This repo's core concepts — Environment, Runner, Command, Terraform module — are defined in [CONTEXT.md](./CONTEXT.md). Read that first if any of the terms below are unfamiliar.

## Layout

- **`terraform/`** — one stack per environment (`dev`, `stage`, `prod`, `mercor`, plus a `jenkins` support stack), a shared `modules/` for reusable resources (`do_droplet`, and the Kubernetes-cluster pieces `infra`/`registry`/`ingress`), and `shared/` for root-level config that's identical across stacks but can't itself be a Terraform module (provider blocks, mainly).
- **`ansible/`** — one role per task area (`setup_server`, `setup_docker`, `setup_app`, ...); the top-level `*.yml` playbooks compose roles per environment.
- **`bin/`** — the Ruby CLI (`infra_cli.rb`) that drives both, plus its test suite (`bin/spec/`).

## Running the CLI

```
ruby bin/infra_cli.rb -c <command> -e <environment> [--tags <tags>]
```

- **`-c`/`--command`** — the method to call on the environment's Runner. What's available depends on the environment's family (`Runners::Cluster` for `stage`/`prod`, `Runners::Droplet` for `dev`/`mercor`) — see `bin/lib/runners/` for the full set (`apply`, `destroy`, `run`, `database`, `stage`/`prod`-specific steps like `infra`/`registry`/`ingress`/`kube`/`restart`, and `console_auth`/`console_football` for a live Rails console).
- **`-e`/`--env`** — which environment: `dev`, `stage`, `prod`, or `mercor`.
- **`--tags`** — optional, comma-separated Ansible tags to scope a run to part of a playbook.

Examples:

```
ruby bin/infra_cli.rb -c apply -e stage           # bring up the staging Kubernetes cluster + app
ruby bin/infra_cli.rb -c database -e dev --tags dump   # dump dev's databases
ruby bin/infra_cli.rb -c console_auth -e stage    # rails console into the running auth pod
```

## Tests

```
cd bin && bundle exec rspec
```
