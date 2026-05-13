#!/usr/bin/env bash

hardhat_module_firewall_usage() {
  cat <<'EOF'
Usage:
  hardhat firewall audit
  hardhat firewall apply [--dry-run] [--yes]
EOF
}

hardhat_module_firewall_audit() {
  hardhat_not_implemented "firewall audit (UFW)"
}

hardhat_module_firewall_apply() {
  hardhat_not_implemented "firewall apply (UFW)"

  if ! hardhat_require_elevated_or_sudo; then
    return 1
  fi

  if ! hardhat_confirm_global "Proceed with firewall baseline apply?"; then
    return 1
  fi

  hardhat_log_info "No changes applied in this phase."
}

hardhat_module_firewall_run() {
  local subcommand="${1:-audit}"
  case "${subcommand}" in
    audit)
      hardhat_module_firewall_audit
      ;;
    apply)
      hardhat_module_firewall_apply
      ;;
    help)
      hardhat_module_firewall_usage
      ;;
    *)
      hardhat_log_error "Unknown firewall subcommand: ${subcommand}"
      hardhat_module_firewall_usage
      return 1
      ;;
  esac
}