# setup_git_credentials

Copies `.git-credentials` and the local `.gitconfig` to the target droplet, so subsequent `git clone`/`git pull` tasks in the invoking role can authenticate against GitHub without prompting.

Extracted from `setup_dev` and `setup_mercor`, which both carried an identical copy of this pair of tasks (and an identical `.git-credentials` file) before this role existed.

## Variables

None — copies a static file and the invoking user's own `~/.gitconfig`.

## Used by

`setup_dev.yml` and `setup_mercor.yml`, via their `roles:` list, run before `setup_dev`/`setup_mercor` themselves.
