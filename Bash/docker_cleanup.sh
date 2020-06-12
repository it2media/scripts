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
# Remove if this is an old intermediate container to launch the real container with docker-compose (compose-launcher)
# Arguments:
#   $1: The docker inspect json (string)
#   $2: Current unix time in seconds since epoch (int)
#   $3: The FinishedAt timespan of the docker inspect json in unix time (seconds since epoch as int)
#   $4: If container is definitivly stopped (not running or restarting and status exited) (true or false)
# Returns:
#   None
#######################################
docker_remove_intermediate_container() {
  local image=$(echo "$1" | jq -r '.[0] | .Config.Image')
  echo "$image"
  if [[ "$image" == null ]]; then
    return 0 # if there should be no image name set, simply silently return
  else
    imagename=".it2media.de/compose-launcher:latest"
    if [[ $image =~ $imagename ]]; then
      echo "image: $imagename found in $image"      
      echo "now_t: $2"
      echo "finished_at_t: $3"
      echo "is_stopped: $4"
      if [[ $is_stopped == true ]]; then
        local m=5 # 5 minutes should be long enough for the intermediate container
        echo "m: $m"
        local difference=$(( 60*m ))        
        local now_t=$2
        local finished_at_t=$3
        local calculated_diff=$(( now_t-finished_at_t ))
        echo "calculated_diff: $calculated_diff"
        if [[ $calculated_diff -gt $difference ]]; then
          echo "true: $calculated_diff > $difference"
          local id=$(echo "$1" | jq -r '.[0] | .Id')
          echo "docker rm $id"
          docker rm "$id"
        fi
      fi
    else
      echo "image: $imagename not found in $image"
    fi
  fi
}

#######################################
# Removes old stopped docker container
# Arguments:
#   $1: The docker inspect json
#   $2: The timespan in h
# Returns:
#   None
#######################################
docker_remove_stopped() {
  local now=$(date +%Y-%m-%dT%H:%M:%S)
  local now_t=`date --date="$now" +%s`
  local finished_at=$(echo "$1" | jq -r '.[0] | .State.FinishedAt')
  local finished_at_t=`date --date="$finished_at" +%s`
  local service=$(echo "$1" | jq -r '.[0] | .Config.Labels["com.docker.compose.service"]')
  local restarting=$(echo "$1" | jq -r '.[0] | .State.Restarting')
  local running=$(echo "$1" | jq -r '.[0] | .State.Running')
  local status=$(echo "$1" | jq -r '.[0] | .State.Status')
  local is_stopped=false; [[ $restarting == false && $running == false && $status == "exited" ]] && is_stopped=true || is_stopped=false
  if [[ "$service" == null ]]; then
    echo "null => calling docker_remove_intermediate_container"
    docker_remove_intermediate_container "$1" "$now_t" "$finished_at_t" "$is_stopped"
  else
    echo "$service"    
    echo "now: $now"
    echo "now_t: $now_t"
    if [[ -z "$2" ]]; then
      echo "ERROR: You need to provide a second argument with the timespan in h!"
      return 1
    else
      local h="$2"
      echo "h: $h"
      local difference=$(( 3600*h ))
      echo "difference: $difference"
      echo "finished_at: $finished_at"
      echo "finished_at_t: $finished_at_t"
      local calculated_diff=$(( now_t-finished_at_t ))
      echo "calculated_diff: $calculated_diff"
      if [[ $calculated_diff -gt $difference ]]; then
        echo "true: $calculated_diff > $difference"
        echo "restarting: $restarting"
        echo "running: $running"
        echo "status: $status"        
	      if [[ $is_stopped == true ]]; then
          docker_exists_running "$service"
          if [[ $? -eq 0 ]]; then
            echo "docker_exists_running: 0 / $is_stopped (There is a running service with the same name.)"
            local id=$(echo "$1" | jq -r '.[0] | .Id')
            echo "docker rm $id"
            docker rm "$id"
          else
            echo "No running service found with service name: $service"
          fi
        fi
      else
        echo "false: $calculated_diff > $difference"
      fi
    fi
  fi
}

#######################################
# Removes old stopped docker containers
# Arguments:
#   $1: The timespan in h
# Returns:
#   None
#######################################
docker_cleanup() {
  for container_id in $(docker container ls -a --no-trunc | awk 'FNR == 1 {next}{print $1}')
  do
    local docker_inspect_json=$(docker inspect "$container_id")
    echo ">>>"
    echo "$container_id"
    docker_remove_stopped "$docker_inspect_json" "$1"
    echo "<<<"
  done
  return 0
}
