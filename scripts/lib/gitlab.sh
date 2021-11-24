#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function exist_image_tag_gitlab {
  # $1: Image name (string) [Required]
  # $2: Tag (string) [Required]
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

function remove_registry_image_gitlab {
  # $1: Image name (string) [Required]
  # $2: Tag (string) [Required]

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
