# setup_monitoring

Deploys Prometheus + Alertmanager + Grafana (`server` tag) or just a metrics exporter (`client` tag) via Docker Compose, then (server only) provisions Grafana over its HTTP API: adds the Prometheus datasource if missing, deletes any existing dashboards, and re-imports the CPU/memory dashboards from `templates/*.j2`.

**Likely dead**: `vars/main.yml`'s `servers` list is hardcoded to "Web Server"/"Worker Server"/"Ansible Server" — the pre-Kubernetes single-droplet trio (see `setup_worker`'s README). Only invoked by `setup_worker.yml` and `setup_ansible.yml`, both themselves likely dead. Flagged for the same triage ticket.

## Variables

All in `vars/main.yml` (not `defaults/`): `monitoring_home`, `prometheus_endpoint`, `grafana_endpoint`, `grafana_admin_user`/`grafana_admin_password` (both literally `admin` — worth rotating if this role is kept), `webhook_url`, `servers`.

## Used by

`setup_worker.yml` (`server` tag) and `setup_ansible.yml` (`server` tag). Not invoked by the Ruby CLI.
