#!/bin/bash

if [ -f "/usr/local/lib/ci_cd_lib/tools.sh" ]; then
  source "/usr/local/lib/ci_cd_lib/tools.sh"
else
  source "./tools.sh"
fi

function docker_registry_login {
  # $1: User name (string) [Required]
  # $2: Password (string) [Required]
  # $3: Registry (string) [Required]
  debug "User: \"$1\""
  debug "Registry: \"$3\""
  echo "$2" | docker login -u "$1" --password-stdin "$3"  || error "Failed to login to Docker registry."
}

function docker_build_image {
  # $1: Image name (string) [Required]
  # $2: Docker file name (string) [Optional]
  # $3: Build directory (string) [Optional]
  # $4: Labels (array) [Optional]
  #     Eg: (--label "org.opencontainers.image.title=<a title>"
  #          --label "org.opencontainers.image.title=url=<a url>")
  [ -z "$2" ] && file='Dockerfile' || file=$2
  [ -z "$3" ] && path='.' || path=$3

  debug "Image: \"$1\""
  debug "Docker file: \"${file}\""
  debug "Path: \"$(pwd)/${path}\""

  # Go to the build dir
  cd "./${path}" || error "Cannot cd to '$(pwd)/${path}': No such directory."

  # Do we have a docker file?
  [ ! -f "${file}" ] && error "Cannot locate Docker file '${file}' in directory '$(pwd)/${path}'."

  # Build image
  labels=("${@:4}")
  if [ ${#labels[@]} -gt 0 ]; then
    debug "Labels: ${labels[*]}"
  fi

  docker build -t "$1" "${labels[@]}" -f "${file}" . || error "Failed to build Docker image."
}

function docker_push_image {
  # $1: Tag (string) [Required]
  debug "Push \"$1\""

  docker push "$1" || error "Failed to push Docker image."
}