#!/usr/bin/env bash

hardhat_is_root() {
  [[ "${EUID}" -eq 0 ]]
}

hardhat_has_sudo() {
  command -v sudo >/dev/null 2>&1
}

hardhat_require_elevated_or_sudo() {
  if hardhat_is_root; then
    return 0
  fi

  if hardhat_has_sudo; then
    return 0
  fi

  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    hardhat_log_error "Esta accion requiere privilegios root o disponibilidad de sudo."
  else
    hardhat_log_error "This action requires root privileges or sudo availability."
  fi
  return 1
}