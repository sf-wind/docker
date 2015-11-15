#!/bin/bash

# First start the reverse proxy

CONTAINER_RUNNING=$(docker inspect --format="{{ .State.Running }}" nginx_proxy 2> /dev/null)

if [[ $? -eq 1 ]]; then
  docker run --name nginx_proxy -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
elif [[ "$CONTAINER_RUNNING" == "false" ]]; then
  docker start nginx_proxy
fi



# Then iterate all subdirectories and start them
ROOT_DIR=$1
for dir in $ROOT_DIR/*
do
  if [[ -d $dir ]]; then
    cd $dir
    if [[ -f docker-compose.yml ]]; then
      docker-compose up -d
    fi
  fi
done

