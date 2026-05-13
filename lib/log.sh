#!/usr/bin/env bash

hardhat_log_info() {
  printf '%b[INFO]%b %s\n' "${HARDHAT_COLOR_BLUE}" "${HARDHAT_COLOR_RESET}" "$*"
}

hardhat_log_warn() {
  printf '%b[WARN]%b %s\n' "${HARDHAT_COLOR_YELLOW}" "${HARDHAT_COLOR_RESET}" "$*"
}

hardhat_log_error() {
  printf '%b[ERROR]%b %s\n' "${HARDHAT_COLOR_RED}" "${HARDHAT_COLOR_RESET}" "$*" >&2
}

hardhat_log_success() {
  printf '%b[OK]%b %s\n' "${HARDHAT_COLOR_GREEN}" "${HARDHAT_COLOR_RESET}" "$*"
}

hardhat_log_debug() {
  if [[ "${HARDHAT_VERBOSE:-0}" -eq 1 ]]; then
    printf '[DEBUG] %s\n' "$*"
  fi
}