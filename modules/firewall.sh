#!/usr/bin/env bash

HARDHAT_UFW_INSTALLED=0
HARDHAT_UFW_ACTIVE="unknown"
HARDHAT_UFW_DEFAULT_POLICY="unknown"
HARDHAT_UFW_RULES=()
HARDHAT_FIREWALL_FINDINGS=()
HARDHAT_FIREWALL_NOTES=()
HARDHAT_FIREWALL_RECOMMENDATIONS=()
HARDHAT_FIREWALL_SEVERITY="none"

hardhat_module_firewall_usage() {
  cat <<'EOF'
Usage:
  hardhat firewall audit [--json]
  hardhat firewall apply [--dry-run] [--yes]
EOF
}

hardhat_firewall_reset_state() {
  HARDHAT_UFW_INSTALLED=0
  HARDHAT_UFW_ACTIVE="unknown"
  HARDHAT_UFW_DEFAULT_POLICY="unknown"
  HARDHAT_UFW_RULES=()
  HARDHAT_FIREWALL_FINDINGS=()
  HARDHAT_FIREWALL_NOTES=()
  HARDHAT_FIREWALL_RECOMMENDATIONS=()
  HARDHAT_FIREWALL_SEVERITY="none"
}

hardhat_firewall_add_recommendation() {
  local recommendation="$1"
  local item
  for item in "${HARDHAT_FIREWALL_RECOMMENDATIONS[@]}"; do
    if [[ "${item}" == "${recommendation}" ]]; then
      return 0
    fi
  done
  HARDHAT_FIREWALL_RECOMMENDATIONS+=("${recommendation}")
}

hardhat_firewall_add_note() {
  local note="$1"
  HARDHAT_FIREWALL_NOTES+=("${note}")
  if declare -F hardhat_audit_add_note >/dev/null 2>&1; then
    hardhat_audit_add_note "${note}"
  fi
}

hardhat_firewall_add_finding() {
  local finding_id="$1"
  local severity="$2"
  local title="$3"
  local description="$4"
  local recommendation="$5"

  HARDHAT_FIREWALL_FINDINGS+=("${finding_id}|${severity}|${title}|${description}|${recommendation}")
  hardhat_firewall_add_recommendation "${recommendation}"

  if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
    hardhat_audit_add_finding "${finding_id}" "${severity}" "${title}" "${description}" "${recommendation}"
  fi
}

hardhat_firewall_severity_weight() {
  local severity="$1"
  case "${severity}" in
    critical)
      printf '4'
      ;;
    high)
      printf '3'
      ;;
    medium)
      printf '2'
      ;;
    low)
      printf '1'
      ;;
    *)
      printf '0'
      ;;
  esac
}

hardhat_firewall_compute_severity() {
  local top_weight=0
  local item severity weight
  HARDHAT_FIREWALL_SEVERITY="none"

  for item in "${HARDHAT_FIREWALL_FINDINGS[@]}"; do
    IFS='|' read -r _ severity _ _ _ <<<"${item}"
    weight="$(hardhat_firewall_severity_weight "${severity}")"
    if ((weight > top_weight)); then
      top_weight="${weight}"
      HARDHAT_FIREWALL_SEVERITY="${severity}"
    fi
  done
}

hardhat_firewall_run_ufw_capture() {
  local output
  if output="$(ufw "$@" 2>&1)"; then
    printf '%s' "${output}"
    return 0
  fi

  if ! hardhat_is_root && hardhat_has_sudo; then
    if output="$(sudo -n ufw "$@" 2>&1)"; then
      printf '%s' "${output}"
      return 0
    fi
  fi

  printf '%s' "${output}"
  return 1
}

hardhat_firewall_extract_default_policy() {
  local verbose_output="$1"
  local line
  line="$(awk 'tolower($0) ~ /^default:/ {print; exit}' <<<"${verbose_output}")"
  if [[ -z "${line}" ]]; then
    printf 'unknown'
    return 0
  fi

  line="$(sed -E 's/^[Dd]efault:[[:space:]]*//' <<<"${line}")"
  printf '%s' "$(hardhat_trim "${line}")"
}

hardhat_firewall_extract_rules() {
  local input="$1"
  local line cleaned
  while IFS= read -r line; do
    [[ -z "$(hardhat_trim "${line}")" ]] && continue
    if grep -qiE '^(status:|to[[:space:]]+action[[:space:]]+from|--)' <<<"${line}"; then
      continue
    fi

    cleaned="$(sed -E 's/^\[[[:space:]]*[0-9]+\][[:space:]]*//' <<<"${line}")"
    if grep -qiE '(ALLOW|DENY|REJECT)' <<<"${cleaned}"; then
      HARDHAT_UFW_RULES+=("$(hardhat_trim "${cleaned}")")
    fi
  done <<<"${input}"
}

hardhat_firewall_analyze_rules() {
  if ((${#HARDHAT_UFW_RULES[@]} == 0)); then
    hardhat_firewall_add_note "No explicit UFW rules detected or they could not be parsed."
    return 0
  fi

  hardhat_firewall_add_note "UFW rules detected: ${#HARDHAT_UFW_RULES[@]}."

  local rules_text
  rules_text="$(printf '%s\n' "${HARDHAT_UFW_RULES[@]}")"

  if grep -qiE 'ALLOW IN[[:space:]]+Anywhere( |$)|ALLOW[[:space:]]+Anywhere( |$)' <<<"${rules_text}"; then
    hardhat_firewall_add_finding \
      "firewall.ufw.allow_anywhere" \
      "medium" \
      "Broad allow rule detected" \
      "At least one UFW rule allows inbound traffic from Anywhere without clear source restriction." \
      "Restrict allow rules to trusted source ranges and only required ports."
  fi

  if grep -qiE '(23|3389)(/tcp|/udp)?[[:space:]].*(ALLOW).*(Anywhere)' <<<"${rules_text}"; then
    hardhat_firewall_add_finding \
      "firewall.ufw.risky_port_anywhere" \
      "high" \
      "Risky remote-access rule exposed" \
      "A sensitive port (Telnet or RDP) appears allowed from Anywhere." \
      "Close risky remote-access ports or restrict them to trusted source networks."
  fi
}

hardhat_firewall_generated_at_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown'
}

hardhat_module_firewall_collect_audit() {
  hardhat_firewall_reset_state

  if ! command -v ufw >/dev/null 2>&1; then
    hardhat_firewall_add_note "UFW is not installed."
    hardhat_firewall_add_finding \
      "firewall.ufw.missing" \
      "medium" \
      "UFW not installed" \
      "No supported firewall backend was detected for MVP baseline checks." \
      "Install UFW and define a default deny-incoming policy."
    hardhat_firewall_compute_severity
    return 0
  fi

  HARDHAT_UFW_INSTALLED=1
  hardhat_firewall_add_note "UFW is installed."

  local status_output=""
  if ! status_output="$(hardhat_firewall_run_ufw_capture status)"; then
    hardhat_firewall_add_note "UFW status could not be read with current privileges."
    hardhat_firewall_add_finding \
      "firewall.ufw.status_unavailable" \
      "low" \
      "UFW status unavailable" \
      "HardHat could not retrieve current UFW status output." \
      "Run audit with permissions that allow reading UFW status."
    hardhat_firewall_compute_severity
    return 0
  fi

  if grep -qiE 'status:[[:space:]]*active' <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="yes"
    hardhat_firewall_add_note "UFW is active."
  elif grep -qiE 'status:[[:space:]]*inactive' <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="no"
    hardhat_firewall_add_note "UFW is installed but inactive."
    hardhat_firewall_add_finding \
      "firewall.ufw.inactive" \
      "high" \
      "UFW inactive" \
      "Firewall is installed but not enforcing any filtering rules." \
      "Enable UFW and apply baseline defaults (deny incoming, allow outgoing)."
  else
    hardhat_firewall_add_note "UFW status did not report active or inactive clearly."
  fi

  local status_verbose_output=""
  if status_verbose_output="$(hardhat_firewall_run_ufw_capture status verbose)"; then
    HARDHAT_UFW_DEFAULT_POLICY="$(hardhat_firewall_extract_default_policy "${status_verbose_output}")"
    if [[ "${HARDHAT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
      hardhat_firewall_add_note "UFW default policy could not be extracted."
      hardhat_firewall_add_finding \
        "firewall.ufw.default_unknown" \
        "low" \
        "UFW default policy unknown" \
        "HardHat could not parse default policy from UFW verbose output." \
        "Inspect UFW defaults manually with ufw status verbose."
    else
      hardhat_firewall_add_note "UFW default policy: ${HARDHAT_UFW_DEFAULT_POLICY}."
      if ! grep -qiE '(deny|reject)[[:space:]]*\(incoming\)' <<<"${HARDHAT_UFW_DEFAULT_POLICY}"; then
        hardhat_firewall_add_finding \
          "firewall.ufw.default_incoming" \
          "medium" \
          "Weak default incoming policy" \
          "UFW default incoming policy is not deny/reject." \
          "Set UFW default incoming policy to deny."
      fi
    fi
  else
    hardhat_firewall_add_note "UFW verbose output unavailable for default policy check."
  fi

  local rules_output=""
  if rules_output="$(hardhat_firewall_run_ufw_capture status numbered)"; then
    hardhat_firewall_extract_rules "${rules_output}"
  elif rules_output="$(hardhat_firewall_run_ufw_capture status)"; then
    hardhat_firewall_extract_rules "${rules_output}"
  else
    hardhat_firewall_add_note "UFW rules output unavailable."
  fi

  hardhat_firewall_analyze_rules
  hardhat_firewall_compute_severity
}

hardhat_module_firewall_render_human() {
  local findings_count="${#HARDHAT_FIREWALL_FINDINGS[@]}"
  printf 'HardHat Firewall Audit\n'
  printf 'Backend: UFW\n'
  printf 'Installed: %s\n' "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf yes || printf no )"
  printf 'Active: %s\n' "${HARDHAT_UFW_ACTIVE}"
  printf 'Default policy: %s\n' "${HARDHAT_UFW_DEFAULT_POLICY}"
  printf 'Rules detected: %s\n' "${#HARDHAT_UFW_RULES[@]}"
  printf 'Overall severity: %s\n' "${HARDHAT_FIREWALL_SEVERITY}"
  printf 'Findings: %s\n\n' "${findings_count}"

  local note
  for note in "${HARDHAT_FIREWALL_NOTES[@]}"; do
    printf -- '- %s\n' "${note}"
  done

  if ((findings_count > 0)); then
    printf '\nDetailed findings:\n'
    local idx=1
    local item id severity title description recommendation
    for item in "${HARDHAT_FIREWALL_FINDINGS[@]}"; do
      IFS='|' read -r id severity title description recommendation <<<"${item}"
      printf '%s. [%s] %s (%s)\n' "${idx}" "${severity}" "${title}" "${id}"
      printf '   Description: %s\n' "${description}"
      printf '   Recommendation: %s\n' "${recommendation}"
      idx=$((idx + 1))
    done
  else
    printf '\nNo weak firewall configuration detected with current checks.\n'
  fi

  if ((${#HARDHAT_FIREWALL_RECOMMENDATIONS[@]} > 0)); then
    printf '\nRecommendations:\n'
    local rec
    for rec in "${HARDHAT_FIREWALL_RECOMMENDATIONS[@]}"; do
      printf -- '- %s\n' "${rec}"
    done
  fi
}

hardhat_module_firewall_render_json() {
  local generated_at
  local item id severity title description recommendation
  local idx=0

  generated_at="$(hardhat_firewall_generated_at_utc)"

  printf '{'
  printf '"metadata":{'
  printf '"tool":"hardhat",'
  printf '"version":"%s",' "$(hardhat_json_escape "${HARDHAT_VERSION:-unknown}")"
  printf '"command":"firewall audit",'
  printf '"generated_at":'
  hardhat_json_nullable_string "${generated_at}"
  printf '},'

  printf '"firewall":{'
  printf '"backend":"ufw",'
  printf '"ufw_installed":%s,' "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf true || printf false )"
  printf '"active":'
  hardhat_json_nullable_string "${HARDHAT_UFW_ACTIVE}"
  printf ','
  printf '"default_policy":'
  hardhat_json_nullable_string "${HARDHAT_UFW_DEFAULT_POLICY}"
  printf ','
  printf '"rules_count":%s,' "${#HARDHAT_UFW_RULES[@]}"
  printf '"rules":'
  hardhat_json_print_string_array "${HARDHAT_UFW_RULES[@]}"
  printf '},'

  printf '"summary":{'
  printf '"severity":"%s",' "$(hardhat_json_escape "${HARDHAT_FIREWALL_SEVERITY}")"
  printf '"findings_count":%s' "${#HARDHAT_FIREWALL_FINDINGS[@]}"
  printf '},'

  printf '"notes":'
  hardhat_json_print_string_array "${HARDHAT_FIREWALL_NOTES[@]}"
  printf ','

  printf '"findings":['
  for item in "${HARDHAT_FIREWALL_FINDINGS[@]}"; do
    IFS='|' read -r id severity title description recommendation <<<"${item}"
    if ((idx > 0)); then
      printf ','
    fi
    printf '{'
    printf '"id":"%s",' "$(hardhat_json_escape "${id}")"
    printf '"severity":"%s",' "$(hardhat_json_escape "${severity}")"
    printf '"title":"%s",' "$(hardhat_json_escape "${title}")"
    printf '"description":"%s",' "$(hardhat_json_escape "${description}")"
    printf '"recommendation":"%s"' "$(hardhat_json_escape "${recommendation}")"
    printf '}'
    idx=$((idx + 1))
  done
  printf '],'

  printf '"recommendations":'
  hardhat_json_print_string_array "${HARDHAT_FIREWALL_RECOMMENDATIONS[@]}"
  printf '}'
  printf '\n'
}

hardhat_module_firewall_audit() {
  hardhat_module_firewall_collect_audit

  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    hardhat_module_firewall_render_json
    return 0
  fi

  hardhat_module_firewall_render_human
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