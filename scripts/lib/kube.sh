#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function kube_set_image {
  # $1: file set as file path (string) [Required]
  # $2: kind (string) [Required]
  # $3: container name (string) [Required]
  # $4: container image (string) [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""
  debug "Container name: \"$3\""
  debug "Container image: \"$4\""

  yq e -i "select(.kind==\"$2\") |= .spec.template.spec.containers[] |= select(.name==\"$3\").image=\"$4\"" "$1"
}

function kube_apply {
  # $1: file set as file path (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl apply --kubeconfig="$2" -f "$1" || error "Failed to apply $1."
}

function kube_delete {
  # $1: file set as file path (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl delete --kubeconfig="$2" -f "$1" || error "Failed to delete."
}

function kube_describe {
  # $1: file set as file path (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl describe --kubeconfig="$2" -f "$1" || error "Failed to describe $1."
}

function kube_status {
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  # $3: timeout (string) [Optional]
  [ -z "$3" ] && timeout="3m" || timeout=$3

  debug "Status of: \"$1\""
  debug "Config file: \"$2\""
  debug "Timeout: \"${timeout}\""

  kubectl rollout status --kubeconfig="$2" --timeout="${timeout}" "$1" || error "Failed to get status."
}
