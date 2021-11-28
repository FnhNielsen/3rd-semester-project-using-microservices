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
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl describe "$1" --kubeconfig="$2" || error "Failed to describe $1."
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

function kube_service_pods {
  # $1: "<kind>/<name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "Get pod(s) for: \"$1\""
  debug "Config file: \"$2\""

  # shellcheck disable=SC2207
  _split=($(echo "$1" | tr "/" "\n"))
  if [ "${_split[0]}" == "statefulset" ]; then
    selector_names="${_split[1]}"
    exp="[0-9]+"
  else
    selector_names="$(kubectl get "$1" -o json --kubeconfig="$2" | jq -r ".spec.selector.matchLabels | .[]")"
    exp="[a-z0-9]+-[a-z0-9]+"
  fi

  for selector_name in ${selector_names}; do
    debug "Selector name: \"${selector_name}\""
    kubectl get pod -o json --kubeconfig="$2" | jq -r ".items[] | select(.metadata.name? | match(\"^${selector_name}-${exp}$\")) | .metadata.name"
  done
}

function kube_service_pod_log {
  # $1: "<kind>/<name>" (string) [Required]
  # $2: pod name (string) [Required]
  # $3: config; file set as file path (string) [Required]
  debug "Kind/name: \"$1\""
  debug "Pod: \"$2\""
  debug "Config file: \"$3\""

  for container_name in $(kubectl get "$1" -o json --kubeconfig="$3" | jq -r ".spec.template.spec.containers[].name"); do
    debug "Container name: \"${container_name}\""
    kubectl logs "$2" "${container_name}" --kubeconfig="$3" || error "Failed to get log."
  done
}
