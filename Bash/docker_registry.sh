#!/usr/bin/env bash
#
# Tags an image found in the registry with a git commit id from develop as "master" by searching the latest commit id from the develop branch via git log in the current (master) branch.

#######################################
# Tags an image found in the registry with a git commit id from develop as "master" by searching the latest commit id from the develop branch via git log in the current (master) branch.
# Arguments:
#   $1: The base address of the docker registry server without trailing backslash. e.g. https://registry.it2media.de
#   $2: The name of the docker image. e.g. testwebapp, salesdatacore, salesdatacontrol, ...
#   $3: The number of history entries to respect while searching a suitable commit id in the tags list of the registry server.
#       This normally should be one of the latest commits, because this is triggered immediately after merging the develop or release to master and pushing the master branch.
#       When merging a release branch there might be the possibility, that multiple other commits were made, for example tags, versionsing, CHANGELOG entries and so on.
#       But 100 should be sufficient in nearly all cases.
# Returns:
#   None
#######################################
docker_registry_tag_master_image() {
  .
}

#######################################
# Gets an array of tags for an image in a docker registry
# Arguments:
#   $1: The base address of the docker registry server without trailing backslash. e.g. https://registry.it2media.de
#   $2: The name of the docker image. e.g. testwebapp, salesdatacore, salesdatacontrol, ...
# Returns:
#   The array of available tags for this docker image
#######################################
docker_registry_gettagslist() {
  .
}

#######################################
# Returns true as soon the given string is found in an array of strings
# Arguments:
#   $1: The string to search for
#   $2: The array of strings to search in
# Returns:
#   true if the string is found, false if not
#######################################
string_array_contains() {
  local searchstr="$1"
  shift
  local arr=("$@")
  for string in "${arr[@]}";
  do
    echo "Test: $searchstr $string"
  done
}
