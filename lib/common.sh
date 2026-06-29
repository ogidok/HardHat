#!/usr/bin/env bash

# Exit-code contract for MVP CLI behavior.
HARDHAT_EXIT_SUCCESS=0
HARDHAT_EXIT_WARNING=10
HARDHAT_EXIT_USAGE=2
HARDHAT_EXIT_OPERATIONAL=20
HARDHAT_EXIT_ABORTED=30

hardhat_is_json_mode() {
  [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]
}

hardhat_require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    hardhat_log_error "Missing required command: ${cmd}"
    return 1
  fi
}

hardhat_trim() {
  local value="$*"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

hardhat_join_by() {
  local delimiter="$1"
  shift || true
  local first=1
  local item
  for item in "$@"; do
    if [[ "${first}" -eq 1 ]]; then
      printf '%s' "${item}"
      first=0
    else
      printf '%s%s' "${delimiter}" "${item}"
    fi
  done
}

hardhat_not_implemented() {
  local feature="$1"
  hardhat_log_warn "${feature} is not implemented yet."
}