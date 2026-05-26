#!/usr/bin/env bash

hardhat_json_escape() {
  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//\"/\\\"}"
  input="${input//$'\t'/\\t}"
  input="${input//$'\r'/\\r}"
  input="${input//$'\n'/\\n}"
  printf '%s' "${input}"
}

hardhat_json_kv() {
  local key="$1"
  local value="$2"
  printf '"%s":"%s"' "$(hardhat_json_escape "${key}")" "$(hardhat_json_escape "${value}")"
}

hardhat_json_nullable_string() {
  local value="${1:-}"
  if [[ -z "${value}" ]] || [[ "${value}" == "unknown" ]] || [[ "${value}" == "n/a" ]]; then
    printf 'null'
    return 0
  fi

  printf '"%s"' "$(hardhat_json_escape "${value}")"
}

hardhat_json_print_string_array() {
  local item
  local idx=0
  printf '['
  for item in "$@"; do
    if ((idx > 0)); then
      printf ','
    fi
    printf '"%s"' "$(hardhat_json_escape "${item}")"
    idx=$((idx + 1))
  done
  printf ']'
}