#!/usr/bin/env bash

hardhat_confirm_global() {
  local message="${1:-Apply proposed security changes?}"

  if [[ "${HARDHAT_ASSUME_YES:-0}" -eq 1 ]]; then
    hardhat_log_warn "Auto-confirm enabled by --yes"
    return 0
  fi

  read -r -p "${message} [y/N]: " answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      hardhat_log_info "Operation cancelled by user."
      return 1
      ;;
  esac
}