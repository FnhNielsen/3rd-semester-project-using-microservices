#!/bin/bash

if [ -f "/usr/local/lib/ci_cd_lib/tools.sh" ]; then
  source "/usr/local/lib/ci_cd_lib/tools.sh"
else
  source "./tools.sh"
fi

function kube_set_image {
  # $1: file set as file path (string) [Required]
  # $2: kind (string) [Required]
  # $3: container name (string) [Required]
  # $4: container image (string) [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""
  debug "Container name: \"$3\""
  debug "Container image: \"$4\""

  if [ "$(yq e "select(.kind==\"$2\").spec.template.spec.containers[] | select(.name==\"$3\").name" "$1")" != "$3" ]; then
    error_return "Container \"$3\" could not be found."
  fi

  # Set imag
  yq e -i "select(.kind==\"$2\") |= .spec.template.spec.containers[] |= select(.name==\"$3\").image=\"$4\"" "$1"

  # Is image set
  image_name=$(yq e "select(.kind==\"$2\").spec.template.spec.containers[] | select(.name==\"$3\").image" "$1")
  if [ "${image_name}" != "$4" ]; then
    error_return "Unable to set image."
  fi
}

function kube_apply {
  # $1: file set as file path (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl apply --kubeconfig="$2" -f "$1" || error_return "Failed to apply $1."
}

function kube_delete {
  # $1: file set as file path (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl delete --kubeconfig="$2" -f "$1" || error_return "There was a deletion error."
}

function kube_describe {
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Config file: \"$2\""

  kubectl describe "$1" --kubeconfig="$2" || error_return "Failed to describe $1."
}

function kube_status {
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  # $3: timeout (string) [Optional]
  [ -z "$3" ] && timeout="3m" || timeout=$3

  debug "Status of: \"$1\""
  debug "Config file: \"$2\""
  debug "Timeout: \"${timeout}\""

  kubectl rollout status --kubeconfig="$2" --timeout="${timeout}" "$1" || error_return "Failed to get status."
}

function kube_get_kinds {
  # $1: file; set as file path (string) [Required]
  debug "File: \"$1\""

  for kind in $(yq e ".kind" "$1"); do
    if [ "${kind}" != "---" ]; then
      debug "kind: \"${kind}\""
      echo "${kind}"
    fi
  done
}

function kube_get_service_names {
  # $1: file; set as file path (string) [Required]
  # $2: kind [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""

  for name in $(yq e "select(.kind==\"$2\") | .metadata.name" "$1"); do
    if [ "${name}" != "---" ]; then
      debug "name: \"${name}\""
      echo "${name}"
    fi
  done
}

function kube_service_pods {
  # $1: "<kind>/<name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "Get pod(s) for: \"$1\""
  debug "Config file: \"$2\""

  selector_names="$(kubectl get "$1" -o json --kubeconfig="$2" | jq -r ".metadata.name")"
  # shellcheck disable=SC2207
  _split=($(echo "$1" | tr "/" "\n"))
  if [ "${_split[0]}" == "statefulset" ]; then
    exp="[0-9]+"
  else
    selector_names="${selector_names} $(kubectl get "$1" -o json --kubeconfig="$2" | jq -r ".spec.selector.matchLabels | .[]")"
    exp="[a-z0-9]+-[a-z0-9]+"
  fi

  pods=()
  for selector_name in ${selector_names}; do
    debug "Selector name: \"${selector_name}\""
    pods+=("$(kubectl get pod -o json --kubeconfig="$2" | jq -r ".items[] | select(.metadata.name? | match(\"^${selector_name}-${exp}$\")) | .metadata.name")")
  done

  echo "${pods[*]}" | xargs -n1 | sort -u | xargs
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
    kubectl logs "$2" "${container_name}" --kubeconfig="$3" || error_return "Failed to get log."
  done
}

function kube_container_status {
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]

  debug "Status of: \"$1\""
  debug "Config file: \"$2\""

  kubectl get --kubeconfig="$2" -o json "$1" | jq -r ".status.containerStatuses[] | .state | keys | unique | .[]"
}

function kube_get {
  # $1: "<kind>/<service name>" (string) [Required]
  # $2: config; file set as file path (string) [Required]

  debug "Status of: \"$1\""
  debug "Config file: \"$2\""

  kubectl get --kubeconfig="$2" "$1" || error_return "Failed to get $1."
}

function kube_top_pod {
  # $1: pod name (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "Name: \"$1\""
  debug "Config file: \"$2\""

  kubectl top pod --kubeconfig="$2" "$1" || error_return "Failed to get resource use."
}

# container
function kube_container_exec {
  # $1: pod name (string) [Required]
  # $2: container name (string) [Required]
  # $3: cmd (string) [Required]
  # $4: config; file set as file path (string) [Required]
  pod=$1
  container=$2
  eval "cmd_array=($3)"
  config=$4

  debug "Pod name: \"$1\""
  debug "Container name: \"$2\""
  debug "Command: $3"
  debug "Config file: \"$4\""

  kubectl exec --kubeconfig="${config}" --stdin --tty "${pod}" -c "${container}" -- "${cmd_array[@]}"
}
