#!/usr/bin/env bash

hardhat_detect_arch_linux() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    [[ "${ID:-}" == "arch" ]]
    return
  fi

  return 1
}