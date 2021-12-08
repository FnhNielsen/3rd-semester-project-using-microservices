#!/bin/bash

if [ -f "/usr/local/lib/ci_cd_lib/tools.sh" ]; then
  source "/usr/local/lib/ci_cd_lib/tools.sh"
else
  source "./tools.sh"
fi


## Common
function _kube_get_unique_values {
  # $1: values (string) [Required]
  # $2: filter (string) [Optional]
  debug "Values: \"$1\""
  debug "Filter: \"$2\""

  values=$(echo " " | xargs -I"$2" echo " $1 " | xargs -n1 | sort -u | xargs)
  debug "Result values: \"${values}\""
  echo "${values}"
}


## Kube file methods
function kube_get_kind {
  # $1: file; set as file path (string) [Required]
  # $2: service name [Required]
  debug "File: \"$1\""
  debug "Service name: \"$2\""

  _kube_get_unique_values "$(yq e "select(.metadata.name==\"$2\") | .kind" "$1")" "---"
}

function kube_get_kinds {
  # $1: file; set as file path (string) [Required]
  debug "File: \"$1\""

  _kube_get_unique_values "$(yq e ".kind" "$1")" "---"
}

function kube_get_service_name {
  # $1: file; set as file path (string) [Required]
  # $2: kind [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""

  yq e "select(.kind==\"$2\") | .metadata.name" "$1"
}

function kube_get_service_names {
  # $1: file; set as file path (string) [Required]
  debug "File: \"$1\""

  _kube_get_unique_values "$(yq e ".metadata.name" "$1")" "---"
}

function kube_get_container_names {
  # $1: file; set as file path (string) [Required]
  # $2: kind (string) [Required]
  # $3: service name (string) [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""
  debug "Service name: \"$3\""

  _kube_get_unique_values "$(yq e "select(.kind==\"$2\") | select(.metadata.name==\"$3\") | .spec.template.spec.containers | .[] | .name" "$1")" "---"
}


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


## Kube methods
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

function kube_get {
  # $1: kind (string) [Required]
  # $2: name (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "Kind: \"$1\""
  debug "Name: \"$2\""
  debug "Config file: \"$3\""

  kubectl get --kubeconfig="$3" "${1,,}/$2" || error_return "Failed to get $1/$2."
}

function kube_describe {
  # $1: kind (string) [Required]
  # $2: name (string) [Required]
  # $3: config; file set as file path (string) [Required]
  debug "Kind: \"$1\""
  debug "Name: \"$2\""
  debug "Config file: \"$3\""

  kubectl describe "${1,,}/$2" --kubeconfig="$3" || error_return "Failed to describe $1/$2."
}

function kube_status {
  # $1: kind (string) [Required]
  # $2: service name (string) [Required]
  # $3: config; file set as file path (string) [Required]
  # $4: timeout (string) [Optional]
  debug "Kind: \"$1\""
  debug "Service name: \"$2\""
  debug "Config file: \"$3\""
  debug "Timeout: \"$4\""

  kubectl rollout status --kubeconfig="$3" --timeout="$4" "${1,,}/$2" || error_return "Failed to get status."
}

# pod
function kube_get_pods {
  # $1: file; set as file path (string) [Required]
  # $2: kind (string) [Required]
  # $3: service name (string) [Required]
  # $4: config; file set as file path (string) [Required]
  debug "File: \"$1\""
  debug "Kind: \"$2\""
  debug "Service name: \"$3\""
  debug "Config file: \"$4\""

  # Get selector names
  case ${2,,} in
    statefulset)
      selector_names=$3
      exp="[0-9]+"
    ;;
    deployment)
      selector_names=$(_kube_get_unique_values "$3 $(yq e "select(.metadata.name==\"$3\") | .spec.selector.matchLabels | .[]" "$1")" "---")
      exp="[a-z0-9]+-[a-z0-9]+"
    ;;
  esac
  debug "Selector names: \"${selector_names}\""

  for selector_name in ${selector_names}; do
    debug "Selector name: \"${selector_name}\""
    kubectl get pod -o json --kubeconfig="$4" | jq -r ".items[] | select(.metadata.name? | match(\"^${selector_name}-${exp}$\")) | .metadata.name"
  done
}

function kube_pod_log {
  # $1: pod name (string) [Required]
  # $2: container name (string) [Required]
  # $3: config; file set as file path (string) [Required]
  debug "Pod: \"$1\""
  debug "Container name: \"$2\""
  debug "Config file: \"$3\""

  kubectl logs "pod/$1" "$2" --kubeconfig="$3" || error_return "Failed to get log."
}

function kube_top_pod {
  # $1: pod name (string) [Required]
  # $2: config; file set as file path (string) [Required]
  debug "Pod name: \"$1\""
  debug "Config file: \"$2\""

  kubectl top pod --kubeconfig="$2" "$1" || error_return "Failed to get resource use."
}

# container
function kube_container_status {
  # $1: pod name (string) [Required]
  # $2: container name (string) [Required]
  # $3: config; file set as file path (string) [Required]
  debug "Pod name: \"$1\""
  debug "Container name: \"$2\""
  debug "Config file: \"$3\""

  kubectl get --kubeconfig="$3" -o json "pod/$1" | jq -r ".status.containerStatuses[] | select(.name == \"$2\").state | keys | .[]"
}

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
