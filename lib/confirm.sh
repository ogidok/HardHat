#!/usr/bin/env bash

hardhat_confirm_global() {
  local message="${1:-Apply proposed security changes?}"

  if [[ "${HARDHAT_ASSUME_YES:-0}" -eq 1 ]]; then
    if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
      hardhat_log_warn "Confirmacion automatica habilitada por --yes"
    else
      hardhat_log_warn "Auto-confirm enabled by --yes"
    fi
    return 0
  fi

  read -r -p "${message} [y/N]: " answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
        hardhat_log_info "Operacion cancelada por el usuario."
      else
        hardhat_log_info "Operation cancelled by user."
      fi
      return 1
      ;;
  esac
}