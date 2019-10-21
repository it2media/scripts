#!/usr/bin/env bash
#
# Stops a docker container by entrypoint name and port

#######################################
# Stops a docker container by entrypoint name and port
# Arguments:
#   $1: The docker containers entrypoint process name
#   $2: The published port to search for
# Returns:
#   None
#######################################
docker_stop() {
  for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
  do
    docker_inspect_json=$(docker inspect "$n")
    echo "$1 $2 $container_id $docker_inspect_json"
  done
}