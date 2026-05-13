#!/usr/bin/env bash

hardhat_json_escape() {
  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//\"/\\\"}"
  input="${input//$'\n'/\\n}"
  printf '%s' "${input}"
}

hardhat_json_kv() {
  local key="$1"
  local value="$2"
  printf '"%s":"%s"' "$(hardhat_json_escape "${key}")" "$(hardhat_json_escape "${value}")"
}