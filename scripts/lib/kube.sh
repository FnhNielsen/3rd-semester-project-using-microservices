#!/bin/bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/tools.sh"

function kube_set_image {
  # $1: file set as file path (string) [Required]
  # $2: container name (string) [Required]
  # $3: container image (string) [Required]
  debug "File: \"$1\""
  debug "Container name: \"$2\""
  debug "Container image: \"$3\""

  yq e -i "select(.kind==\"Deployment\") |= .spec.template.spec.containers[] |= select(.name==\"$2\").image=\"$3\"" "$1"
}

function kube_apply {
  # $1: file set as file path (string) [Required]
  # $2: config file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl apply --kubeconfig="$2" -f "$1" || error "Failed to apply."
}

function kube_delete {
  # $1: file set as file path (string) [Required]
  # $2: config file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl apply --kubeconfig="$2" -f "$1" || error "Failed to delete."
}
