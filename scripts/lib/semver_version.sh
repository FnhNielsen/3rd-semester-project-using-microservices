#!/bin/bash

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "${LIB_DIR}/tools.sh"

function format_version {
  # $1: Version (string)
  # $2: Format (string)
  #     Format values (major|minor|patch|release|prerel|build) separated by space
  #     Eg. major minor prerel
  #     See https://github.com/fsaintjacques/semver-tool
  f_ver=""

  echo "Input Version: \"$1\"" >&2
  echo "Format: \"$2\"" >&2

  for part in $2; do
    case ${part} in
      prerel)
        p=$(semver get prerel "$1")
        [ -n "$p" ] && f_ver="${f_ver}${p:+-$p}"
      ;;
      build)
        p=$(semver get build "$1")
        [ -n "$p" ] && f_ver="${f_ver}${p:++$p}"
      ;;
      *)
        p=$(semver get "${part}" "$1")
        [ -n "$p" ] && f_ver="${f_ver}${p:+.$p}"
      ;;
    esac
  done

  echo "Formatted version: \"${f_ver:1}\"" >&2
  echo "${f_ver:1}"
}

function check_version_scheme {
  # $1: Version (string)
  debug "Version: \"$1\""
  is_empty "$1"
  semver get patch "$1" > /dev/null 2>&1
}

function normalize_version {
  # $1: Version (string)
  debug "Version: $1"

  prerel=$(semver get prerel "$1")
  debug "Prerel: ${prerel}"

  release=$(semver get release "$1")
  debug "Release: ${release}"

  debug "Normalize version: ${release}${prerel:+-$prerel}"
  echo "${release}${prerel:+-$prerel}"
}

function is_newer_version {
  # $1: Old version (string)
  # $2: New version (string)
  debug "Compare $1 with $2"
  [ "$(semver compare "$1" "$2")" == "-1" ]
}
