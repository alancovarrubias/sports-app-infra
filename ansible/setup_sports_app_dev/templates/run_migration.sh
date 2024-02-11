#! /bin/bash
docker-compose run auth rake db:create
docker-compose run auth rake db:migrate