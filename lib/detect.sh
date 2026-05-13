#!/usr/bin/env bash

hardhat_detect_distro_id() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    printf '%s' "${ID:-unknown}"
    return 0
  fi

  printf '%s' "unknown"
  return 1
}

hardhat_detect_arch_linux() {
  [[ "$(hardhat_detect_distro_id)" == "arch" ]]
}

hardhat_require_arch_or_exit() {
  if hardhat_detect_arch_linux; then
    return 0
  fi

  hardhat_log_error "HardHat MVP currently supports only Arch Linux."
  exit 1
}