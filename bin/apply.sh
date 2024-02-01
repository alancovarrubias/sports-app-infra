#!/bin/bash

terraform -chdir="$(pwd)/terraform/ansible_jenkins" apply --auto-approve