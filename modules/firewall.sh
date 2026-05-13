#!/usr/bin/env bash

hardhat_module_firewall_usage() {
  cat <<'EOF'
Usage:
  hardhat firewall audit
  hardhat firewall apply [--dry-run] [--yes]
EOF
}

hardhat_module_firewall_audit() {
  hardhat_log_info "Firewall audit (UFW) not implemented yet (stub)."
}

hardhat_module_firewall_apply() {
  hardhat_log_warn "Firewall apply is scaffolded but not implemented yet."

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