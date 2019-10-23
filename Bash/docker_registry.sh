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
  image_tags=$(docker_registry_gettagslist "$1" "$2")
  commit_ids=$(git log -"$3" --pretty=format:"%H")

  echo "---------------"
  echo "Tags on server:"
  echo "---------------"
  for tag in $image_tags;
  do
    echo "$tag"
  done

  echo "---------------"
  echo "Processing commit_ids in git log history:"
  echo "---------------"
  for commit_id in $commit_ids;
  do
    echo "$commit_id"
    found_commit_in_tags=$(string_array_contains "$commit_id" $image_tags)
    echo "$found_commit_in_tags"
    if [[ "$found_commit_in_tags" == true ]]; then
      registry=${1#*//}
      echo "$registry"
      image_to_pull="$registry/$2:$commit_id"
      image_tagged_master="$registry/$2:master"
      echo "$image_to_pull"
      cat /srv/docker/password.registry.it2media.de | docker login --username it2media --password-stdin "$registry"
      docker pull "$image_to_pull"
      docker tag "$image_to_pull" "$image_tagged_master"
      docker push "$image_tagged_master"
      return 0
    fi
  done
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
  tags_list_url="$1/v2/$2/tags/list"
  #echo "Gettings tags from $tags_list_url"

  #https://stackoverflow.com/questions/46540047/passing-password-to-curl-on-command-line/53282815#53282815
  #Do not output result of "curl" with > /dev/null 2>&1 as we only need the tags information itself for further processing. https://www.linuxquestions.org/questions/linux-newbie-8/what-is-the-@echo-off-alternative-for-a-shell-script-780842/
  cat /srv/docker/password.registry.it2media.de | sed -e "s/^/-u it2media:/" | curl -o tags-list.json "$tags_list_url" -K- > /dev/null 2>&1

  #read json, pipe it to jq with -r (raw output), read tags and unwrap the array with .[] to remove the separating comma
  cat tags-list.json | jq -r '.tags | .[]'
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
  for string_from_array in "${arr[@]}";
  do
    if [[ "$searchstr" ==  "$string_from_array" ]]; then
      echo true
      return 0
    fi
  done
  echo false
}
