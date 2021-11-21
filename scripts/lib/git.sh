#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function get_git_commit_sha {
  sha="$(git log --pretty=format:%h --no-merges -n 1 HEAD)"

  debug "SHA: ${sha}"
  echo "${sha}"
}

function add_git_tag {
  # $1: Tag (string) [Required]
  # $2: Commit SHA (string) [Required]
  debug "Tag: \"$1\""
  debug "Commit SHA: \"$2\""
  git tag "$1" "$2"
}

function push_git_tag {
  debug "push tags to origin branch"
  git push origin --tags
}

