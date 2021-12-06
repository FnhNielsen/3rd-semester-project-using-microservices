#!/bin/bash

if [ -f "/usr/local/lib/ci_cd_lib/tools.sh" ]; then
  source "/usr/local/lib/ci_cd_lib/tools.sh"
else
  source "./tools.sh"
fi

function check_version_scheme {
  # $1: Version (string) [Required]
  debug "Version: \"$1\""
  is_empty "$1"
  semver get patch "$1" > /dev/null 2>&1
}

function normalize_version {
  # $1: Version (string) [Required]
  debug "Version: $1"

  prerel=$(semver get prerel "$1")
  debug "Prerel: ${prerel}"

  release=$(semver get release "$1")
  debug "Release: ${release}"

  debug "Normalize version: ${release}${prerel:+-$prerel}"
  echo "${release}${prerel:+-$prerel}"
}
