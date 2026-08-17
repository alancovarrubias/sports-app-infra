# database_cmd

Database operations against a droplet's own Dockerized Postgres (`docker run --network host postgres:15 ...`), selected by tag:

- **`dump`** — `pg_dump` each service's database, fetch the `.sql` files back to the control machine.
- **`restore`** — stop the app containers, drop and recreate each service's database, copy dump files up, `psql` them back in, restart.
- **`create`** — create + migrate + seed fresh databases (used for a first-time setup).

`env` (`dev`/`stage`/`prod`) is mapped to a database-name suffix via `value_map` (`dev` → `development`, `stage`/`prod` → `production`) — this role only makes sense against a `Droplet`-family environment (`dev`/`mercor`), since `stage`/`prod` use managed Kubernetes Postgres, not a Docker container.

## Variables

- `env` — which environment's databases to operate on.
- `services`, `db_containers` — which app services have databases (see `extra_vars.yml`).
- `user_name`, `repo_name` — for locating the Docker Compose project on the droplet.
- `postgres_password` — for the `restore` tag's `psql` connection.

## Used by

`database_cmd.yml`, invoked via `Runners::Droplet#database` (ticket 001) — e.g. `ruby bin/infra_cli.rb -c database -e dev --tags dump`. Previously only reachable by hand-running `ansible-playbook`; now a real CLI command like everything else.
