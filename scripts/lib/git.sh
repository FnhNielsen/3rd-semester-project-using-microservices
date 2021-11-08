#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/gitlab.sh"

function get_git_commit_sha {
  is_merge_production_gitlab \
    && git rev-parse --short HEAD^1 \
    || echo "${CI_COMMIT_SHORT_SHA}"
}

function add_git_tag {
  # $1: version
  # $2: commit SHA
  git tag "${1}" "${2}"
}

function push_git_tag {
  # $1: branch
  git push "${1:='origin'}" --tags
}
