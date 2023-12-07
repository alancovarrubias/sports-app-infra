#!/bin/bash
aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 678549062078.dkr.ecr.us-west-1.amazonaws.com

docker tag client:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/client:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/client:prod

docker tag server:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/server:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/server:prod

docker tag auth:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/auth:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/auth:prod

docker tag football:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/football:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/football:prod

docker tag sidekiq:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/sidekiq:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/sidekiq:prod

docker tag crawler:prod 678549062078.dkr.ecr.us-west-1.amazonaws.com/crawler:prod
docker push 678549062078.dkr.ecr.us-west-1.amazonaws.com/crawler:prod
