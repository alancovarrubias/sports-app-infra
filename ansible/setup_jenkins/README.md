# setup_jenkins

Builds and runs the custom Jenkins image on its droplet: copies the Dockerfile, `plugins.txt`, Jenkins Configuration-as-Code (`jenkins.yaml`), AWS credentials, and an SSH private key, builds the `custom-jenkins` image (only rebuilding when the Dockerfile or plugin list changed), and starts it via Docker Compose. Also has a `plugins` tag that queries a running Jenkins instance's installed plugin versions (for regenerating `plugins.txt` — the task that writes the file back out is currently commented out).

## Variables

- `jenkins_user`, `jenkins_password`, `jenkins_port` — for the `plugins` tag's API call.
- `ansible_host` — the target droplet (from inventory).

## Used by

`setup_jenkins.yml`, tag `jenkins`. Not invoked by the Ruby CLI — no `Runners` class targets a `jenkins` environment; run directly with `ansible-playbook`.
