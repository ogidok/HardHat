#!/usr/bin/env bash

hardhat_sudo_run() {
  if [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]]; then
    hardhat_log_info "[dry-run] sudo $*"
    return 0
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}