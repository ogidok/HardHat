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