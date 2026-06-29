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

hardhat_json_generated_at_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown'
}

hardhat_json_print_metadata() {
  local command="$1"
  local generated_at="$2"

  printf '"metadata":{'
  printf '"tool":"hardhat",'
  printf '"version":"%s",' "$(hardhat_json_escape "${HARDHAT_VERSION:-unknown}")"
  printf '"command":"%s",' "$(hardhat_json_escape "${command}")"
  printf '"generated_at":'
  hardhat_json_nullable_string "${generated_at}"
  printf '}'
}

hardhat_json_print_status() {
  local result="$1"
  local exit_code="$2"
  local message="$3"

  printf '"status":{'
  printf '"result":"%s",' "$(hardhat_json_escape "${result}")"
  printf '"exit_code":%s,' "${exit_code}"
  printf '"message":"%s"' "$(hardhat_json_escape "${message}")"
  printf '}'
}