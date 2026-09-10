# sports-app-infra

Infrastructure-as-code for deploying and operating the sports-app across environments, using Terraform, Ansible, and a Ruby CLI that orchestrates both.

## Language

**Environment**:
One of the named deployment targets — `dev`, `stage`, `prod`, `mercor` — each with its own Terraform stack (`terraform/<environment>/`) and Ansible playbook (`ansible/setup_<environment>.yml`). The same environment name threads through the Ruby CLI, Terraform's `-chdir`, and Ansible's `env=` variable.
_Avoid_: module, mod — "module" collides with Terraform's own module concept (see below).

**Runner**:
A Ruby class (`Runners::Cluster`, `Runners::Droplet`) that orchestrates the Terraform and Ansible steps for one Environment, exposing lifecycle methods like `apply`/`destroy`/`run`. One Runner class handles every Environment in its family — differences between Environments in the same family (e.g. stage vs. prod) are a handful of internal branches on the Environment name, not separate subclasses.
_Avoid_: module, command; avoid inventing a subclass per Environment — that's the shape this repo deliberately moved away from (see git history for `Runners::Stage`/`Prod`/`Dev`/`Mercor`).

**Droplet** (Runner family):
`Runners::Droplet` — Environments backed by a single DigitalOcean droplet running Docker Compose (`dev`, `mercor`). One `terraform apply`, then one Ansible playbook to configure the droplet. `dev` is the only Environment with a default Ansible tag set (so an untagged run still bootstraps a fresh machine); `mercor` has none (an untagged run there means "run everything").

**Cluster** (Runner family):
`Runners::Cluster` — Environments backed by a DigitalOcean Kubernetes cluster, DOKS (`stage`, `prod`). A fixed sequence — infra, registry, ingress, optionally DNS, then the app itself via Ansible — where each Terraform step's outputs must be reloaded before the next step reads them. `prod` is the only Environment with its own domain, so it's the only one that runs the DNS step, and the only one that exposes `apply_base`/`destroy_base` (rebuild everything except DNS).

**Command** (Ruby):
An object (`Commands::Terraform`, `Commands::Ansible`, `Commands::Kubectl`, `Commands::Database`) that turns a Runner's request into the literal shell command line for one tool. `Terraform`/`Ansible`/`Kubectl` are pure string-builders with no orchestration logic — the Runner still runs what they build. `Database` is the deliberate exception: it also validates the `-d` database argument and executes its own `pg_dump`/`psql` commands, since dump/restore is a self-contained operation a Runner shouldn't need to know the shape of.
_Avoid_: runner, task.

**Terraform module**:
Terraform's own native concept — a reusable unit of resources (`terraform/modules/do_droplet`, `terraform/modules/do_network`) or one of the named pieces of a stack targeted via `-target=module.<name>` (e.g. `infra`, `registry`, `ingress`, `dns`). Unrelated to Environment, despite the shared word "module" that appeared in the CLI's flag before it was renamed to `--env`/`-e`.
_Avoid_: using bare "module" for Environment — always say "Terraform module" for this concept, "Environment" for that one.
