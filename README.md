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
ruby bin/infra_cli.rb -c <command> -e <environment> [--tags <tags>] [-d <database>]
```

- **`-c`/`--command`** — the method to call on the environment's Runner. What's available depends on the environment's family (`Runners::Cluster` for `stage`/`prod`, `Runners::Droplet` for `dev`/`mercor`) — see `bin/lib/runners/` for the full set (`apply`, `destroy`, `run`, `database`, `stage`/`prod`-specific steps like `infra`/`registry`/`ingress`/`kube`/`restart`, and `console`/`seed`/`dump`/`restore` for a single app's database).
- **`-e`/`--env`** — which environment: `dev`, `stage`, `prod`, or `mercor`.
- **`--tags`** — optional, comma-separated Ansible tags to scope a run to part of a playbook.
- **`-d`/`--database`** — required by `-c console`/`-c seed`/`-c dump`/`-c restore` to pick which app's database to target (`auth` or `football`).
- **`-s`/`--service`** — optional, for `-c registry`/`-c restart` on `stage`/`prod`, to scope the run to one service instead of every deployment. One of `client`, `server`, `auth`, `football`, `crawler`, `sidekiq` (see `Runners::Cluster::DEPLOYMENTS`).

Examples:

```
ruby bin/infra_cli.rb -c apply -e stage           # bring up the staging Kubernetes cluster + app
ruby bin/infra_cli.rb -c database -e dev --tags dump   # dump dev's databases
ruby bin/infra_cli.rb -c console -e stage -d auth      # rails console into the running auth pod
ruby bin/infra_cli.rb -c seed -e stage -d football     # run db/seeds.rb in the running football pod
ruby bin/infra_cli.rb -c dump -e stage -d auth         # dump stage's auth database to a local file
ruby bin/infra_cli.rb -c restore -e stage -d auth      # restore stage's auth database from that local file
ruby bin/infra_cli.rb -c registry -e stage -s crawler  # rebuild+push+restart just the crawler (see below)
```

## Redeploying a single service

To ship a code change to one service on `stage`/`prod` without rebuilding and restarting everything:

1. **Build the image locally**, tagged the way that environment expects it. `stage` uses `local_image_tag: prod` (see `Runners::Cluster#ansible_variables`), so even though you're deploying to stage, you build with `ENV=prod`:
   ```
   cd sports-app
   ENV=prod docker compose -f docker-compose.build.yml build crawler
   ```
   `prod` really does build with `ENV=prod` — `local_image_tag` only exists to give `stage` its own separate local tag.

2. **Push it and restart just that deployment**, with `-s`/`--service`:
   ```
   cd sports-app-infra/bin
   ruby infra_cli.rb -c registry -e stage -s crawler
   ```
   This tags and pushes only `crawler`'s image (skipping `client`/`server`/`auth`/`football`), then runs `kubectl rollout restart` on only the `crawler` deployment — the rest of the app is untouched. `-s sidekiq` is a special case: sidekiq has no image of its own (it runs `football`'s), so `-s sidekiq` pushes nothing and only restarts the `sidekiq` deployment.

   Omit `-s` to push every image in `Runners::Cluster::REGISTRY_CONTAINERS` and restart every currently-running deployment, same as before this flag existed.

3. **Verify the rollout:**
   ```
   KUBECONFIG=~/.kube/sports-app.yaml kubectl rollout status deployment/crawler --timeout=120s
   ```

## Tests

```
cd bin && bundle exec rspec
```
