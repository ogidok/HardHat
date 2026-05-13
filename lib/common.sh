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