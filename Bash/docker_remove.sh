#!/usr/bin/env bash
#
# Removes old stopped docker container

#######################################
# Check if this is a running docker container with that entrypoint name
# Arguments:
#   $1: The docker containers com.docker.compose.service name
#   $2: The docker inspect json
# Returns:
#   Exit code 0 on success, 1 on failure
#######################################
docker_is_running() {
  local service=$(echo "$2" | jq -r '.[0] | .Config.Labels["com.docker.compose.service"]')
  if [[ "$service" == "$1" ]]; then
      local has_state_running=$(echo "$2" | jq -r '.[0] | .State.Running')
      local status=$(echo "$2" | jq -r '.[0] | .State.Status')
      if [[ "$has_state_running" == true && "$status" == "running" ]]; then
        return 0 # 0 is success exit code so equivalent to true
      fi
  fi
  return 1 # every other exit code than 0 is an error code (false)
}

#######################################
# Check if there is a running docker container with that entrypoint name
# Arguments:
#   $1: The docker containers com.docker.compose.service name
# Returns:
#   Exit code 0 for true, 1 for false
#######################################
docker_exists_running() {
  for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
  do
    local docker_inspect_json=$(docker inspect "$container_id")
    docker_is_running "$1" "$docker_inspect_json" && return 0 # if we found any running container for this service, we return true
  done
  return 1 # if no running container was found for this service name we return false
}

#######################################
# Removes old stopped docker container
# Arguments:
#   $1: The docker inspect json
# Returns:
#   None
#######################################
docker_remove_stopped() {
  local service=$(echo "$1" | jq -r '.[0] | .Config.Labels["com.docker.compose.service"]')
  echo "$service"
  docker_exists_running "$service"
  if [[ $? -eq 0 ]]; then
    echo "There is a running service with the same service name"
  else
    echo "No running service found with service name: $1"
  fi
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
    local docker_inspect_json=$(docker inspect "$container_id")
    docker_remove_stopped "$docker_inspect_json"
  done
}
