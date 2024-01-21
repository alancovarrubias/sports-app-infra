#!/bin/bash

# Change permissions of /var/run/docker.sock
chmod 666 /var/run/docker.sock

# Execute the CMD from the Dockerfile
exec "$@"