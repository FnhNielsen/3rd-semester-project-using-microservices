#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/gitlab.sh"

function get_new_version {
  is_merge_production_gitlab \
    && ${CI_COMMIT_DESCRIPTION} | awk '{print $1;}' \
    || echo ${CI_MERGE_REQUEST_TITLE}
}

function check_semver_scheme {
  # $1: version
  semver get patch "${1:='none'}" > /dev/null 2>&1
}

function normalize_version {
  # $1: version
  prerel=$(semver get prerel "${1}")
  build=$(semver get build "${1}")

  echo "$(semver get release "${1}")${prerel:+-$prerel}${build:++$build}"
}

function is_newer_version {
  # $1: old version
  # $2: new version
  [ "$(semver compare "$1" "$2")" -eq -1 ]
}

function is_release_version {
  # $1: version
  [ -z "$(semver get prerel "$1")" ]
}
