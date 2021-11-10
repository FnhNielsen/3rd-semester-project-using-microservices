#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function get_git_commit_sha {
  # $1: Go backward (string) [Optional]
  [ -z "$1" ] && back=0 || back=$1
  sha=$(git rev-parse --short "HEAD~${back}")

  debug "SHA: ${sha}"
  echo "${sha}"
}

function add_git_tag {
  # $1: Tag (string)
  # $2: Commit SHA (string)
  debug "Tag: \"$1\""
  debug "Commit SHA: \"$2\""
  git tag "$1" "$2"
}

function push_git_tag {
  # $1: Branch (string) [Optional]
  is_empty "$1" && branch="origin" || branch=$1

  debug "push tags to \"${branch}\" branch"
  git push "${branch}" --tags
}
