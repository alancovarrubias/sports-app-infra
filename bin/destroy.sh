#!/bin/bash

terraform -chdir="$(pwd)/terraform" destroy --auto-approve