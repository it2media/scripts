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

#######################################
# Pulls a docker image, stops any running container of this type and composes a new one based on the newer image
# Arguments:
#   $1: The docker registry URL without leading https://, e.g. registry.it2media.de
#   $2: Username for docker registry, e.g. it2media
#   $3: Path to password file for container registry e.g. /mnt/salesdatacore/ContainerRegistry/login/it2media
#   $4: Imagename (with optional tag) to pull: e.g. salesdatacore:latest
#   $5: Docker compose service name: e.g. salesdatacore-dev
#   $6: Relativ path to docker-compose file in git repository: e.g. docker-compose.dev.yml
#   $7: The docker containers entrypoint process name of the to stop container, e.g. IT2media.SalesDataCore.dll
#   $8: The published port of the to stop container, e.g. 24143
# Returns:
#   None
#######################################
docker_pull_stop_and_run() {
  echo "Pull environment image and copy latest compose file for this environment"
  cat "$3" | docker login --username "$2" --password-stdin "$1"
  docker pull "$1/$4"
  mkdir "$5"
  mv "$6" "$5/docker-compose.yml"
  echo "Load latest stop script and stop container with specific entrypoint and port and start a new one with the docker-compose file for this environment"
  cd "$5"
  docker_stop "$7" "$8"
  docker-compose --project-name "$(basename $PWD)-$(date +%Y%m%d%H%M%S)" up -d
}
