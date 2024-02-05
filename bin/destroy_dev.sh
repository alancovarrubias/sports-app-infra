#!/bin/bash

terraform -chdir="$(pwd)/terraform/sports_app_dev" destroy --auto-approve