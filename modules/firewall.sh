#!/usr/bin/env bash

HARDHAT_UFW_INSTALLED=0
HARDHAT_UFW_ACTIVE="unknown"
HARDHAT_UFW_DEFAULT_POLICY="unknown"

hardhat_module_firewall_usage() {
  cat <<'EOF'
Usage:
  hardhat firewall audit
  hardhat firewall apply [--dry-run] [--yes]
EOF
}

hardhat_module_firewall_collect_audit() {
  HARDHAT_UFW_INSTALLED=0
  HARDHAT_UFW_ACTIVE="unknown"
  HARDHAT_UFW_DEFAULT_POLICY="unknown"

  if ! command -v ufw >/dev/null 2>&1; then
    hardhat_audit_add_note "UFW is not installed."
    hardhat_audit_add_finding \
      "firewall.ufw.missing" \
      "medium" \
      "UFW not installed" \
      "No supported firewall backend was detected for MVP baseline checks." \
      "Install UFW and define a default deny-incoming policy."
    return 0
  fi

  HARDHAT_UFW_INSTALLED=1
  hardhat_audit_add_note "UFW is installed."

  local status_output
  local status_verbose_output
  local status_cmd=(ufw status)
  local status_verbose_cmd=(ufw status verbose)

  if ! hardhat_is_root && hardhat_has_sudo; then
    status_cmd=(sudo -n ufw status)
    status_verbose_cmd=(sudo -n ufw status verbose)
  fi

  if ! status_output="$("${status_cmd[@]}" 2>&1)"; then
    hardhat_audit_add_note "UFW status could not be read with current privileges."
    hardhat_audit_add_finding \
      "firewall.ufw.status_unavailable" \
      "low" \
      "UFW status unavailable" \
      "HardHat could not retrieve current UFW status output." \
      "Run audit with permissions that allow reading UFW status."
    return 0
  fi

  if grep -qi "Status: active" <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="yes"
    hardhat_audit_add_note "UFW is active."
  elif grep -qi "Status: inactive" <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="no"
    hardhat_audit_add_note "UFW is installed but inactive."
    hardhat_audit_add_finding \
      "firewall.ufw.inactive" \
      "high" \
      "UFW inactive" \
      "Firewall is installed but not enforcing any filtering rules." \
      "Enable UFW and apply baseline defaults (deny incoming, allow outgoing)."
  else
    hardhat_audit_add_note "UFW status did not report active or inactive clearly."
  fi

  if status_verbose_output="$("${status_verbose_cmd[@]}" 2>/dev/null)"; then
    local default_line
    default_line="$(grep -i '^Default:' <<<"${status_verbose_output}" || true)"
    if [[ -n "${default_line}" ]]; then
      HARDHAT_UFW_DEFAULT_POLICY="$(hardhat_trim "${default_line#Default:}")"
      hardhat_audit_add_note "UFW default policy: ${HARDHAT_UFW_DEFAULT_POLICY}."
      if ! grep -qi 'deny (incoming)' <<<"${default_line}"; then
        hardhat_audit_add_finding \
          "firewall.ufw.default_incoming" \
          "medium" \
          "Weak default incoming policy" \
          "UFW default incoming policy is not deny." \
          "Set UFW default incoming policy to deny."
      fi
    else
      hardhat_audit_add_note "UFW default policy could not be extracted."
      hardhat_audit_add_finding \
        "firewall.ufw.default_unknown" \
        "low" \
        "UFW default policy unknown" \
        "HardHat could not parse default policy from UFW verbose output." \
        "Inspect UFW defaults manually with ufw status verbose."
    fi
  else
    hardhat_audit_add_note "UFW verbose output unavailable for default policy check."
  fi
}

hardhat_module_firewall_audit() {
  hardhat_module_firewall_collect_audit

  if [[ "${HARDHAT_UFW_INSTALLED}" -eq 0 ]]; then
    hardhat_log_warn "UFW is not installed."
    return 0
  fi

  hardhat_log_info "UFW active: ${HARDHAT_UFW_ACTIVE}"
  hardhat_log_info "UFW default policy: ${HARDHAT_UFW_DEFAULT_POLICY}"
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