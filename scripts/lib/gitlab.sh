#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/docker.sh"

function is_merge_production_gitlab {
  [ "${CI_PIPELINE_SOURCE}" == "push" ] && [ "${CI_BUILD_REF_NAME}" == "${CI_CD_PRODUCTION_BRANCH}" ]
}

function exist_tag_gitlab {
  # $1: image name
  # $2: tag
  #
  # Checking if tag is free
  _curl="curl --header \"PRIVATE-TOKEN: ${PROJECT_TOKEN}\" \"https://gitlab.sdu.dk/api/v4/projects/${CI_PROJECT_ID}/registry/repositories\""

  image_id=$("${_curl}/" | jq ".[] | select(.name == \"${1}\") | .id")

  [ -n "${image_id}" ] && [ "$("${_curl}/${image_id}/tags" | jq ". | map(.name==\"${2}\") | any")" == "true" ]
}

function pull_image_gitlab {
  # $1: image name
  # $2: tag
  pull_image "${CI_REGISTRY_IMAGE}/${1}:${2}"
}

function build_image_gitlab {
  # $1: image name
  # $2: tag
  # $3: docker file name
  # $4: build directory (path)
  build_image "${CI_REGISTRY_IMAGE}/${1}:${2}" "${3}" "${4}"
}

function tag_image_gitlab {
  # $1: image name
  # $2: source tag
  # $3: target tag
  tag_image "${CI_REGISTRY_IMAGE}/${1}:${2}" "${CI_REGISTRY_IMAGE}/${1}:${3}"
}

function push_image_gitlab {
  # $1: Image name
  # $2: tag

  registry_login "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"

  push_image "${CI_REGISTRY_IMAGE}/${1}:${2}"
}

function remove_image_gitlab {
  # $1: Image name
  # $2: tag
  #
  # Remove container images from CI/CD: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/40096

  # Delete image from the registry
  curl -u "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" "https://gitlab.com/jwt/auth?account=${CI_REGISTRY_USER}&scope=repository:${CI_REGISTRY_IMAGE}/${1}:delete&service=container_registry";
  reg -d -r "${CI_REGISTRY}" -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" rm "${CI_PROJECT_PATH}/${1}:${2}";
}
