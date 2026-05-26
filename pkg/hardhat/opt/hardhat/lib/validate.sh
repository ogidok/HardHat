#!/usr/bin/env bash

hardhat_validate_non_empty() {
  local value="$1"
  [[ -n "$(hardhat_trim "${value}")" ]]
}

hardhat_validate_choice() {
  local value="$1"
  shift
  local option
  for option in "$@"; do
    if [[ "${value}" == "${option}" ]]; then
      return 0
    fi
  done
  return 1
}

hardhat_validate_boolean_like() {
  local value="$1"
  hardhat_validate_choice "${value}" 0 1 true false yes no
}

hardhat_validate_language_code() {
  local value="$1"
  hardhat_validate_choice "${value}" en es
}