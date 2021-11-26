#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function get_git_commit_sha {
  sha="$(git log --pretty=format:%h --no-merges -n 1 HEAD)"

  debug "SHA: ${sha}"
  echo "${sha}"
}
