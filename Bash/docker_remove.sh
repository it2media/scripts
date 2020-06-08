#!/usr/bin/env bash
#
# Removes old stopped docker container

#######################################
# Check if this is a running docker container with that entrypoint name
# Arguments:
#   $1: The docker containers com.docker.compose.service name
#   $2: The docker inspect json
# Returns:
#   ???????????????????????????????????????????????????????????????????????????????????????????????????
#######################################
docker_is_running() {
  service=$(echo "$2" | jq -r '.[0] | .Config.Labels["com.docker.compose.service"]')
  if [[ "$service" == "$1" ]]; then
      has_state_running=$(echo "$2" | jq -r '.[0] | .State.Running')
      status=$(echo "$2" | jq -r '.[0] | .State.Status')
      if [[ "$has_state_running" == true && status == "running" ]]; then
        echo true
        return 0 # 0 is success exit code so equivalent to true
      fi
  fi
  echo false
  return 1 # every other exit code than 0 is an error code (false)
}

#######################################
# Check if there is a running docker container with that entrypoint name
# Arguments:
#   $1: The docker containers com.docker.compose.service name
# Returns:
#   ???????????????????????????????????????????????????????????????????????????????????????????????????
#######################################
docker_exists_running() {
  for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
  do
    docker_inspect_json=$(docker inspect "$container_id")
    docker_is_running "$1" "$docker_inspect_json"
  done
}

#######################################
# Removes old stopped docker container
# Arguments:
#   $1: The docker inspect json
# Returns:
#   None
#######################################
docker_remove_stopped() {
  echo "Not implemented yet"
}

#######################################
# Removes old stopped docker containers
# Arguments:
#   None
# Returns:
#   None
#######################################
docker_remove() {
  for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
  do
    docker_inspect_json=$(docker inspect "$container_id")
    docker_remove_stopped "$docker_inspect_json"
  done
}