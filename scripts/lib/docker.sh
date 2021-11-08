#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/error.sh"

function registry_login {
  # $1: user
  # $2: password
  # $3: registry
  echo "${2}" | docker login -u "${1}" --password-stdin "${3}"
}

function pull_image {
  # $1: source tag
  docker pull "${1}"
}

function build_image {
  # $1: tag
  # $2: docker file name
  # $3: build directory (path)
  file=${2:='Dockerfile'}
  path=${3:='.'}

  # Go to the build dir
  cd "./${path}" || error "Cannot cd to '$(pwd)/${path}': No such directory."

  # Do we have a docker file?
  [ ! -f "${file}" ] && error "Cannot locate docker file '${file}' in directory '$(pwd)/${path}'."

  # Build image
  docker build -t "${1}" -f "${file}" .
}

function tag_image {
  # $1: source tag
  # $2: target tag
  docker tag "${1}" "${2}"
}

function push_image {
  # $1: tag
  docker push "${1}"
}