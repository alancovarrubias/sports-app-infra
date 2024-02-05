#!/bin/bash

terraform -chdir="$(pwd)/terraform/anible_jenkins" init
terraform -chdir="$(pwd)/terraform/ansible_jenkins" apply --auto-approve