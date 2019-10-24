#!/usr/bin/env bash
#
# Stops a docker container by entrypoint name and port

#######################################
# Stops a docker container by entrypoint name and port
# Arguments:
#   $1: The docker containers entrypoint process name
#   $2: The published port to search for
#   $3: The current container id
#   $4: The current containers docker inspect json
# Returns:
#   None
#######################################
docker_stop_running() {
  current_name=$(echo "$4" | jq -r '.[0] | .Name')
  current_container_status=$(echo "$4" | jq -r '.[0] | .State.Status')
  current_container_args=$(echo "$4" | jq -r '.[0] | .Args[0]')
  current_container_hostport=$(echo "$4" | jq -r '.[0] | .HostConfig.PortBindings."80/tcp"[0].HostPort')
  echo "-----------------------------------------------------------------------------------------------"
  echo "$current_name $3"
  echo "current_container_status: $current_container_status"
  echo "current_container_args: $current_container_args"
  echo "current_container_hostport: $current_container_hostport"
  [[ "${current_container_status}" == "running" ]] && status_detected=true || status_detected=false
  [[ "${current_container_args}" == "$1" ]] && process_detected=true || process_detected=false
  [[ "${current_container_hostport}" == "$2" ]] && port_detected=true || port_detected=false
  echo "status_detected: $status_detected"
  echo "process_detected: $process_detected"
  echo "port_detected: $port_detected"
  if [[ "$status_detected" == true && "$process_detected" == true && "$port_detected" == true ]]; then
    echo "Stopping container $current_name"
    docker stop "$3"
    new_name="/$1.Port$2.$3"
    if [[ "$current_name" != "$new_name" ]]; then
      echo "Renaming $current_name to $new_name"
      docker rename "$current_name" "$new_name"
    fi
  fi
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
    docker_stop_running "$1" "$2" "$container_id" "$docker_inspect_json"
  done
}