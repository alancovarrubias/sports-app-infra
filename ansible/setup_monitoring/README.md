# setup_monitoring

Deploys Prometheus + Alertmanager + Grafana (`server` tag) or just a metrics exporter (`client` tag) via Docker Compose, then (server only) provisions Grafana over its HTTP API: adds the Prometheus datasource if missing, deletes any existing dashboards, and re-imports the CPU/memory dashboards from `templates/*.j2`.

**Currently unused, kept intentionally**: its only two callers, `setup_worker.yml` and `setup_ansible.yml`, were both confirmed dead and deleted (pre-Kubernetes single-droplet architecture — see ticket 012 on the "Clean Infra Codebase" wayfinder map). This role was kept as a starting point for monitoring some other environment later, not because anything currently invokes it — `vars/main.yml`'s `servers` list (`Web Server`/`Worker Server`/`Ansible Server`) is a stale relic of that deleted trio and would need updating to whatever it's pointed at next.

## Variables

All in `vars/main.yml` (not `defaults/`): `monitoring_home`, `prometheus_endpoint`, `grafana_endpoint`, `grafana_admin_user`/`grafana_admin_password` (both literally `admin` — rotate before pointing this at anything real), `webhook_url`, `servers` (stale — see above).

## Used by

Nothing currently. Not invoked by the Ruby CLI or any surviving playbook.
