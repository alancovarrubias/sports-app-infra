#!/bin/bash

terraform -chdir="$(pwd)/terraform/ansible_jenkins" destroy --auto-approve