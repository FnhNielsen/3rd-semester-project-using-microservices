#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function registry_login {
  # $1: User name (string)
  # $2: Password (string)
  # $3: Registry (string)
  debug "User: \"$1\""
  debug "Registry: \"$3\""
  echo "$2" | docker login -u "$1" --password-stdin "$3"  || error "Failed to login to Docker registry."
}

function pull_image {
  # $1: Tag (string)
  debug "Pull \"$1\""
  docker pull "$1"  || error "Failed to pull Docker image."
}

function build_image {
  # $1: Tag (string)
  # $2: Docker file name (string)
  # $3: Build directory (string)
  # $4: Labels (array)
  #     Eg: (--label "org.opencontainers.image.title=<a title>"
  #          --label "org.opencontainers.image.title=url=<a url>")
  [ -z "$2" ] && file='Dockerfile' || file=$2
  [ -z "$3" ] && path='.' || path=$3

  # Go to the build dir
  debug "cd to \"$(pwd)/${path}\""
  cd "./${path}" || error "Cannot cd to '$(pwd)/${path}': No such directory."

  # Do we have a docker file?
  debug "Docker file: \"${file}\""
  [ ! -f "${file}" ] && error "Cannot locate docker file '${file}' in directory '$(pwd)/${path}'."

  # Build image
  debug "Image: \"$1\""

  labels=("${@:4}")
  if [ ${#labels[@]} -gt 0 ]; then
    debug "Labels: ${labels[*]}"
  fi

  docker build -t "$1" "${labels[@]}" -f "${file}" . || error "Failed to build Docker image."
}

function tag_image {
  # $1: Source tag (string)
  # $2: Target tag (string)
  debug "Tag \"$1\" as \"$2\""

  docker tag "$1" "$2" || error "Failed to tag Docker image."
}

function push_image {
  # $1: Tag (string)
  debug "Push \"$1\""

  docker push "$1" || error "Failed to push Docker image."
}