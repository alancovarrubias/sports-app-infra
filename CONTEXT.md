# sports-app-infra

Infrastructure-as-code for deploying and operating the sports-app across environments, using Terraform, Ansible, and a Ruby CLI that orchestrates both.

## Language

**Environment**:
One of the named deployment targets — `dev`, `stage`, `prod`, `mercor` — each with its own Terraform stack (`terraform/<environment>/`) and Ansible playbook (`ansible/setup_<environment>.yml`). The same environment name threads through the Ruby CLI, Terraform's `-chdir`, and Ansible's `env=` variable.
_Avoid_: module, mod — "module" collides with Terraform's own module concept (see below).

**Runner**:
A Ruby class (`Runners::Dev`, `Runners::Stage`, `Runners::Prod`, `Runners::Mercor`) that orchestrates the Terraform and Ansible steps for one Environment, exposing lifecycle methods like `apply`/`destroy`/`run`. Each inherits its shape from one of two families below, overriding only what differs for its Environment.
_Avoid_: module, command.

**Droplet** (Runner family):
`Runners::Droplet`, the shared base for `Dev` and `Mercor` — Environments backed by a single DigitalOcean droplet running Docker Compose. One `terraform apply`, then one Ansible playbook to configure the droplet.

**Cluster** (Runner family):
`Runners::Cluster`, the shared base for `Stage` and `Prod` — Environments backed by a DigitalOcean Kubernetes cluster (DOKS). A fixed sequence — infra, registry, ingress, optionally DNS, then the app itself via Ansible — where each Terraform step's outputs must be reloaded before the next step reads them.

**Command** (Ruby):
A string-builder (`Commands::Terraform`, `Commands::Ansible`, `Commands::Kubectl`) that turns a Runner's request into the literal shell command line to execute. Holds no orchestration logic — it only knows how to spell one tool's CLI syntax.
_Avoid_: runner, task.

**Terraform module**:
Terraform's own native concept — a reusable unit of resources (`terraform/modules/do_droplet`, `terraform/modules/do_network`) or one of the named pieces of a stack targeted via `-target=module.<name>` (e.g. `infra`, `registry`, `ingress`, `dns`). Unrelated to Environment, despite the shared word "module" that appeared in the CLI's flag before it was renamed to `--env`/`-e`.
_Avoid_: using bare "module" for Environment — always say "Terraform module" for this concept, "Environment" for that one.
