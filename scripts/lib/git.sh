#!/bin/bash

if [ -f "/usr/local/lib/ci_cd_lib/tools.sh" ]; then
  source "/usr/local/lib/ci_cd_lib/tools.sh"
else
  source "./tools.sh"
fi

function get_git_commit_sha {
  sha="$(git log --pretty=format:%h --no-merges -n 1 HEAD)"

  debug "SHA: ${sha}"
  echo "${sha}"
}
