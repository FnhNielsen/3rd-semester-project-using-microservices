#!/bin/bash
function is_empty {
  # $1: String (string)
  [ -z "$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ] && true
  false
}

function get_content {
  # $1: URL (string)
  # $2: Alternative arguments (array) [Optional]
  #     Eg. (--header "PRIVATE-TOKEN: <token>")
  debug "URL: \"$1\""

  opts=("${@:2}")
  if [ ${#opts[@]} -gt 0 ]; then
    debug "Optional arguments: ${opts[*]}"
  fi

  result=$(curl -s "${opts[@]}" "$1")

  debug "Output\n${result:='No content'}"
  echo "${result}"
}

function info {
  # $1: Message (string)
  echo -e "INFO (${FUNCNAME[1]}): $1"
}

function debug {
  # $1: Message (string)
  [ "${DEBUG}" == "1" ] && echo -e "DEBUG (${FUNCNAME[1]}): $1" >&2
}

function error {
  # $1: Message (string)
  echo -e "ERROR (${FUNCNAME[1]}): $1" >&2
  exit 1
}
