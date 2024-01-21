#!/bin/bash

terraform -chdir="$(pwd)/terraform" apply --auto-approve
source ~/.zshrc