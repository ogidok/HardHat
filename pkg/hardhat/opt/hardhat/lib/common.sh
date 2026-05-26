#!/usr/bin/env bash

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