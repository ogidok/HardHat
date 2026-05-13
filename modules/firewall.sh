#!/usr/bin/env bash

HARDHAT_AUDIT_UFW_INSTALLED=0
HARDHAT_AUDIT_UFW_ACTIVE="unknown"
HARDHAT_AUDIT_UFW_DEFAULT_POLICY="unknown"

hardhat_module_firewall_add_finding() {
  if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
    hardhat_audit_add_finding "$@"
  fi
}

hardhat_module_firewall_usage() {
  cat <<'EOF'
Usage:
  hardhat firewall audit
  hardhat firewall apply [--dry-run] [--yes]
EOF
}

hardhat_module_firewall_audit() {
  hardhat_module_firewall_collect

  hardhat_log_info "Firewall audit (UFW):"
  if [[ "${HARDHAT_AUDIT_UFW_INSTALLED}" -eq 1 ]]; then
    hardhat_log_info "- Installed: yes"
  else
    hardhat_log_info "- Installed: no"
  fi
  hardhat_log_info "- Status: ${HARDHAT_AUDIT_UFW_ACTIVE}"
  hardhat_log_info "- Default policy: ${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}"
}

hardhat_module_firewall_collect() {
  local status_output=""
  local status_value=""
  local default_policy=""

  HARDHAT_AUDIT_UFW_INSTALLED=0
  HARDHAT_AUDIT_UFW_ACTIVE="unknown"
  HARDHAT_AUDIT_UFW_DEFAULT_POLICY="unknown"

  if ! command -v ufw >/dev/null 2>&1; then
    hardhat_module_firewall_add_finding \
      "firewall.ufw_missing" \
      "medium" \
      "UFW is not installed" \
      "HardHat could not detect UFW on this system." \
      "Install UFW and define a baseline policy: deny incoming, allow outgoing."
    return 0
  fi

  HARDHAT_AUDIT_UFW_INSTALLED=1

  status_output="$(ufw status verbose 2>/dev/null || true)"
  if [[ -z "${status_output}" ]]; then
    status_output="$(ufw status 2>/dev/null || true)"
  fi

  status_value="$(printf '%s\n' "${status_output}" | awk -F': ' '/^Status:/{print tolower($2); exit}')"
  default_policy="$(printf '%s\n' "${status_output}" | awk -F': ' '/^Default:/{print $2; exit}')"

  if hardhat_validate_non_empty "${status_value}"; then
    HARDHAT_AUDIT_UFW_ACTIVE="${status_value}"
  fi

  if hardhat_validate_non_empty "${default_policy}"; then
    HARDHAT_AUDIT_UFW_DEFAULT_POLICY="${default_policy}"
  fi

  case "${HARDHAT_AUDIT_UFW_ACTIVE}" in
    active)
      ;;
    inactive)
      hardhat_module_firewall_add_finding \
        "firewall.ufw_inactive" \
        "high" \
        "UFW is installed but inactive" \
        "Firewall protection is currently disabled." \
        "Enable UFW and apply a minimal inbound deny policy."
      ;;
    *)
      hardhat_module_firewall_add_finding \
        "firewall.ufw_status_unknown" \
        "low" \
        "Unable to determine UFW status" \
        "HardHat could not read firewall status output." \
        "Run ufw status manually and verify firewall state."
      ;;
  esac

  if [[ "${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
    hardhat_module_firewall_add_finding \
      "firewall.ufw_default_unknown" \
      "low" \
      "Unable to determine UFW default policy" \
      "HardHat could not parse default UFW policy from command output." \
      "Run ufw status verbose and validate incoming/outgoing defaults."
    return 0
  fi

  if ! printf '%s\n' "${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}" | grep -qi 'deny (incoming)'; then
    hardhat_module_firewall_add_finding \
      "firewall.ufw_incoming_not_deny" \
      "medium" \
      "UFW incoming default is not deny" \
      "The baseline recommended policy is deny for incoming traffic." \
      "Set UFW default incoming policy to deny."
  fi

  if ! printf '%s\n' "${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}" | grep -qi 'allow (outgoing)'; then
    hardhat_module_firewall_add_finding \
      "firewall.ufw_outgoing_not_allow" \
      "low" \
      "UFW outgoing default is not allow" \
      "Baseline policy commonly allows outgoing traffic by default." \
      "Review outbound policy to avoid accidental service disruption."
  fi
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