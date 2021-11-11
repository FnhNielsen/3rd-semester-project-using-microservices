#!/bin/bash

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "${LIB_DIR}/tools.sh"
source "${LIB_DIR}/docker.sh"

function get_version_gitlab {
  debug "CI_COMMIT_DESCRIPTION: \"${CI_COMMIT_DESCRIPTION}\""
  debug "CI_MERGE_REQUEST_TITLE: \"${CI_MERGE_REQUEST_TITLE}\""
  if [ -z "${CI_MERGE_REQUEST_TITLE}" ]; then
    for version in ${CI_COMMIT_DESCRIPTION}; do break; done
  else
    version="${CI_MERGE_REQUEST_TITLE}"
  fi

  debug "Version: \"${version}\""
  echo "${version}"
}

function exist_image_tag_gitlab {
  # $1: Image name (string)
  # $2: Tag (string) [optional]
  url="https://gitlab.sdu.dk/api/v4/projects/${CI_PROJECT_ID}/registry/repositories"
  header=(--header "PRIVATE-TOKEN: ${CI_CD_PROJECT_TOKEN}")

  debug "Image name: \"$1\""

  # Lookup docker images
  content=$(get_content "${url}" "${header[@]}")
  if is_empty "${content}" || [ "$(echo "${content}" | jq ". | type!=\"array\"")" == "true" ]; then
    error "Wrong response."
  fi

  # Get docker image id if there is one
  image_id=$(echo "${content}" | jq ".[] | select(.name == \"$1\") | .id")
  debug "Image id: \"${image_id}\""

  debug "Image tag: \"$2\""
  # Return false if we do not have an image id,
  # there can not be a tag without an image
  if [ -z "${image_id}" ]; then
    false
  # Return true, if we have a image id
  # and we do not need to check tag
  elif [ -z "$2" ]; then
    true
  else
    # Lookup tags
    content=$(get_content "${url}/${image_id}/tags" "${header[@]}")
    if is_empty "${content}" || [ "$(echo "${content}" | jq ". | type!=\"array\"")" == "true" ]; then
      error "Wrong response."
    fi

    # Is the tag occupied?
    result="$(echo "${content}" | jq ". | map(.name==\"$2\") | any")"
    debug "Tag exist: ${result}"
    [ "${result}" == "true" ]
  fi
}

function pull_image_gitlab {
  # $1: Image name (string)
  registry_login "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"

  pull_image "${CI_REGISTRY_IMAGE}/$1"
}

function build_image_gitlab {
  # $1: Image name (string)
  # $2: Docker file name (string)
  # $3: Build directory (string)
  labels=(--label "org.opencontainers.image.title=${CI_PROJECT_TITLE}" \
          --label "org.opencontainers.image.url=${CI_PROJECT_URL}" \
          --label "org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
          --label "org.opencontainers.image.revision=${CI_COMMIT_SHA}" \
          --label "org.opencontainers.image.source=${CI_PROJECT_URL}/-/tree/${CI_CD_PRODUCTION_BRANCH}")

  build_image "${CI_REGISTRY_IMAGE}/$1" "$2" "$3" "${labels[@]}"
}

function tag_image_gitlab {
  # $1: Source image name (string)
  # $2: Target image name (string)
  tag_image "${CI_REGISTRY_IMAGE}/$1" "${CI_REGISTRY_IMAGE}/$2"
}

function push_image_gitlab {
  # $1: Image name (string)
  registry_login "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"

  push_image "${CI_REGISTRY_IMAGE}/$1"
}

function remove_image_gitlab {
  # $1: Image name (string)
  # $2: Tag (string)

  # Remove images from container registry:
  # https://gitlab.com/gitlab-org/gitlab-foss/-/issues/40096
  url="https://gitlab.com/jwt/auth?account=${CI_REGISTRY_USER}&scope=repository:${CI_REGISTRY_IMAGE}/$1:delete&service=container_registry"
  user=(--user "\"${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}\"")

  content=$(get_content "${url}" "${user[@]}")

  debug "Registry: \"${CI_REGISTRY}\""
  debug "User: \"${CI_REGISTRY_USER}\""
  debug "Remove: \"${CI_PROJECT_PATH}/$1:$2\""
  reg -d -r "${CI_REGISTRY}" -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" rm "${CI_PROJECT_PATH}/$1:$2"
}
