#!/usr/bin/env bash
#
# Stops a docker container by entrypoint name and port

# prüfen ob die Installation von jq dokumentiert ist, oder per bootsteapping ins ci.yml einbauen
docker_stop_running() {
  current_name=$(echo "$4" | jq -r '.[0] | .Name')
  echo "$1 $2 $3 $current_name"
}

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
    docker_inspect_json=$(docker inspect "$container_id")
    docker_stop_running "$1 $2 $container_id $docker_inspect_json"
  done
}