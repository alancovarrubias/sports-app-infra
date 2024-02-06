#!/bin/bash

if [ "$1" == "prod" ]; then
    path="ansible_jenkins"
elif [ "$1" == "dev" ]; then
    path="sports_app_dev"
fi
terraform -chdir="$(pwd)/terraform/$path" destroy --auto-approve
