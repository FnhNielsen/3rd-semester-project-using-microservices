#!/bin/bash
function is_empty {
  # $1: String (string) [Required]
  if [ -z "$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ]; then
    true
  else
    false
  fi
}

function get_content {
  # $1: URL (string) [Required]
  # $2: Alternative arguments (array) [Optional]
  #     Eg. (--header "PRIVATE-TOKEN: <token>")
  debug "URL: \"$1\""

  opts=("${@:2}")
  if [ ${#opts[@]} -gt 0 ]; then
    debug "Optional arguments: ${opts[*]}"
  fi

  result=$(curl -s "${opts[@]}" "$1")
  retVal=$?
  if [ "$retVal" -ne "0" ]; then
    error "An unknown error occurred."
  fi

  debug "Output\n${result:='No content'}"
  echo "${result}"
}

function info {
  # $1: Message (string) [Required]
  echo -e "INFO (${FUNCNAME[1]}): $1"
}

function debug {
  # $1: Message (string) [Required]
  [ "${DEBUG}" == "1" ] && echo -e "DEBUG (${FUNCNAME[1]}): $1" >&2
}

function error {
  # $1: Message (string) [Required]
  echo -e "ERROR (${FUNCNAME[1]}): $1" >&2
  exit 1
}
