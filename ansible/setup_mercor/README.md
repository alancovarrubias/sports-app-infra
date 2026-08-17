# setup_mercor

Sets up the `mercor` droplet as a development environment: copies git credentials, clones the working repo, and installs a Python/Node toolchain (pyenv, Node 20, Claude Code CLI) via apt/npm. Distinct from the app-hosting environments — this droplet is for interactive development work, not for running the sports-app itself.

**Flagged, not fixed here**: `setup_working_repo.yml` downloads a setup script from a signed third-party storage URL with an embedded access token committed in plaintext. Worth a look for the sibling "DevOps Learning Journey" map's Security & Reliability domain — out of scope for this documentation-only ticket.

## Variables

- `user_name` — SSH/deploy user.

## Used by

`setup_mercor.yml`, invoked by `Runners::Mercor` (`-c apply`/`-c run`).
