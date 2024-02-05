#!/bin/bash

terraform -chdir="$(pwd)/terraform/sports_app_dev" init
terraform -chdir="$(pwd)/terraform/sports_app_dev" apply --auto-approve