#!/usr/bin/env bash

hardhat_log_target_fd() {
  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    printf '2'
    return 0
  fi

  printf '1'
}

hardhat_log_info() {
  local target_fd
  target_fd="$(hardhat_log_target_fd)"
  printf '%b[INFO]%b %s\n' "${HARDHAT_COLOR_BLUE}" "${HARDHAT_COLOR_RESET}" "$*" >&"${target_fd}"
}

hardhat_log_warn() {
  local target_fd
  target_fd="$(hardhat_log_target_fd)"
  printf '%b[WARN]%b %s\n' "${HARDHAT_COLOR_YELLOW}" "${HARDHAT_COLOR_RESET}" "$*" >&"${target_fd}"
}

hardhat_log_error() {
  printf '%b[ERROR]%b %s\n' "${HARDHAT_COLOR_RED}" "${HARDHAT_COLOR_RESET}" "$*" >&2
}

hardhat_log_success() {
  local target_fd
  target_fd="$(hardhat_log_target_fd)"
  printf '%b[OK]%b %s\n' "${HARDHAT_COLOR_GREEN}" "${HARDHAT_COLOR_RESET}" "$*" >&"${target_fd}"
}

hardhat_log_debug() {
  if [[ "${HARDHAT_VERBOSE:-0}" -eq 1 ]]; then
    local target_fd
    target_fd="$(hardhat_log_target_fd)"
    printf '[DEBUG] %s\n' "$*" >&"${target_fd}"
  fi
}