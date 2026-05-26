#!/usr/bin/env bash

hardhat_sudo_run() {
  if [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]]; then
    hardhat_log_info "[dry-run] sudo $*"
    return 0
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    if ! command -v sudo >/dev/null 2>&1; then
      if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
        hardhat_log_error "sudo no esta disponible; no se puede ejecutar una accion privilegiada."
      else
        hardhat_log_error "sudo is not available; cannot run privileged action."
      fi
      return 1
    fi
    sudo "$@"
  fi
}