#!/usr/bin/env bash

for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
do
    docker_inspect_json=$(docker inspect "$n")
    echo "$1 $2 $container_id $docker_inspect_json"
done