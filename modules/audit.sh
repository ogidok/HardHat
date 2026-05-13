#!/usr/bin/env bash

HARDHAT_AUDIT_FINDINGS=()
HARDHAT_AUDIT_NOTES=()
HARDHAT_AUDIT_SCORE=100
HARDHAT_AUDIT_SEVERITY="none"

hardhat_audit_reset_state() {
  HARDHAT_AUDIT_FINDINGS=()
  HARDHAT_AUDIT_NOTES=()
  HARDHAT_AUDIT_SCORE=100
  HARDHAT_AUDIT_SEVERITY="none"
}

hardhat_audit_add_note() {
  HARDHAT_AUDIT_NOTES+=("$*")
}

hardhat_audit_add_finding() {
  local finding_id="$1"
  local severity="$2"
  local title="$3"
  local description="$4"
  local recommendation="$5"
  HARDHAT_AUDIT_FINDINGS+=("${finding_id}|${severity}|${title}|${description}|${recommendation}")
}

hardhat_audit_weight_for_severity() {
  local severity="$1"
  case "${severity}" in
    critical)
      printf '40'
      ;;
    high)
      printf '25'
      ;;
    medium)
      printf '15'
      ;;
    low)
      printf '5'
      ;;
    info|none)
      printf '0'
      ;;
    *)
      printf '5'
      ;;
  esac
}

hardhat_audit_calculate_score() {
  local score=100
  local top_weight=0
  local item severity weight

  for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
    IFS='|' read -r _ severity _ _ _ <<<"${item}"
    weight="$(hardhat_audit_weight_for_severity "${severity}")"
    score=$((score - weight))
    if ((weight > top_weight)); then
      top_weight="${weight}"
      HARDHAT_AUDIT_SEVERITY="${severity}"
    fi
  done

  if ((score < 0)); then
    score=0
  fi

  HARDHAT_AUDIT_SCORE="${score}"
}

hardhat_audit_collect() {
  hardhat_audit_add_note "Running baseline checks for firewall, ports, services, SSH and updates."
  hardhat_module_firewall_collect_audit
  hardhat_module_ports_collect_audit
  hardhat_module_services_collect_audit
  hardhat_module_ssh_audit_collect
  hardhat_module_updates_collect_audit
}

hardhat_audit_render_human() {
  local findings_count="${#HARDHAT_AUDIT_FINDINGS[@]}"
  printf 'HardHat Audit Report\n'
  printf 'Summary: baseline security audit completed\n'
  printf 'Score: %s/100\n' "${HARDHAT_AUDIT_SCORE}"
  printf 'Overall severity: %s\n' "${HARDHAT_AUDIT_SEVERITY}"
  printf 'Findings: %s\n\n' "${findings_count}"

  local note
  for note in "${HARDHAT_AUDIT_NOTES[@]}"; do
    printf -- '- %s\n' "${note}"
  done

  if ((findings_count == 0)); then
    printf '\nNo findings detected in this baseline audit.\n'
    return 0
  fi

  printf '\nDetailed findings:\n'
  local idx=1
  local item id severity title description recommendation
  for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
    IFS='|' read -r id severity title description recommendation <<<"${item}"
    printf '%s. [%s] %s (%s)\n' "${idx}" "${severity}" "${title}" "${id}"
    printf '   Description: %s\n' "${description}"
    printf '   Recommendation: %s\n' "${recommendation}"
    idx=$((idx + 1))
  done
}

hardhat_audit_render_json() {
  local findings_count="${#HARDHAT_AUDIT_FINDINGS[@]}"
  printf '{'
  printf '"command":"audit",'
  printf '"summary":"baseline security audit completed",'
  printf '"score":%s,' "${HARDHAT_AUDIT_SCORE}"
  printf '"severity":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_SEVERITY}")"
  printf '"findings_count":%s,' "${findings_count}"

  printf '"notes":['
  local note_idx=0
  local note
  for note in "${HARDHAT_AUDIT_NOTES[@]}"; do
    if ((note_idx > 0)); then
      printf ','
    fi
    printf '"%s"' "$(hardhat_json_escape "${note}")"
    note_idx=$((note_idx + 1))
  done
  printf '],'

  printf '"findings":['
  local idx=0
  local item id severity title description recommendation
  for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
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
  printf ']}'
  printf '\n'
}

hardhat_module_audit_run() {
  hardhat_audit_reset_state
  hardhat_audit_collect
  hardhat_audit_calculate_score

  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    hardhat_audit_render_json
    return 0
  fi

  hardhat_audit_render_human
}