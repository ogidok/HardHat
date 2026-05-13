#!/usr/bin/env bash

HARDHAT_AUDIT_FINDING_IDS=()
HARDHAT_AUDIT_FINDING_SEVERITIES=()
HARDHAT_AUDIT_FINDING_TITLES=()
HARDHAT_AUDIT_FINDING_DESCRIPTIONS=()
HARDHAT_AUDIT_FINDING_RECOMMENDATIONS=()

HARDHAT_AUDIT_TOTAL_FINDINGS=0
HARDHAT_AUDIT_SCORE=100
HARDHAT_AUDIT_OVERALL_SEVERITY="info"
HARDHAT_AUDIT_COUNT_HIGH=0
HARDHAT_AUDIT_COUNT_MEDIUM=0
HARDHAT_AUDIT_COUNT_LOW=0
HARDHAT_AUDIT_COUNT_INFO=0

hardhat_audit_reset_state() {
  HARDHAT_AUDIT_FINDING_IDS=()
  HARDHAT_AUDIT_FINDING_SEVERITIES=()
  HARDHAT_AUDIT_FINDING_TITLES=()
  HARDHAT_AUDIT_FINDING_DESCRIPTIONS=()
  HARDHAT_AUDIT_FINDING_RECOMMENDATIONS=()

  HARDHAT_AUDIT_TOTAL_FINDINGS=0
  HARDHAT_AUDIT_SCORE=100
  HARDHAT_AUDIT_OVERALL_SEVERITY="info"
  HARDHAT_AUDIT_COUNT_HIGH=0
  HARDHAT_AUDIT_COUNT_MEDIUM=0
  HARDHAT_AUDIT_COUNT_LOW=0
  HARDHAT_AUDIT_COUNT_INFO=0
}

hardhat_audit_add_finding() {
  local finding_id="$1"
  local severity="$2"
  local title="$3"
  local description="$4"
  local recommendation="$5"

  HARDHAT_AUDIT_FINDING_IDS+=("${finding_id}")
  HARDHAT_AUDIT_FINDING_SEVERITIES+=("${severity}")
  HARDHAT_AUDIT_FINDING_TITLES+=("${title}")
  HARDHAT_AUDIT_FINDING_DESCRIPTIONS+=("${description}")
  HARDHAT_AUDIT_FINDING_RECOMMENDATIONS+=("${recommendation}")
}

hardhat_audit_severity_rank() {
  local severity="$1"
  case "${severity}" in
    high)
      printf '4'
      ;;
    medium)
      printf '3'
      ;;
    low)
      printf '2'
      ;;
    info)
      printf '1'
      ;;
    *)
      printf '1'
      ;;
  esac
}

hardhat_audit_score_penalty() {
  local severity="$1"
  case "${severity}" in
    high)
      printf '25'
      ;;
    medium)
      printf '12'
      ;;
    low)
      printf '5'
      ;;
    info)
      printf '0'
      ;;
    *)
      printf '3'
      ;;
  esac
}

hardhat_audit_collect() {
  hardhat_module_firewall_collect
  hardhat_module_ports_collect
  hardhat_module_services_collect
  hardhat_module_ssh_audit_collect
  hardhat_module_updates_collect
}

hardhat_audit_calculate_summary() {
  local idx=0
  local severity=""
  local penalty=0
  local current_rank=0
  local candidate_rank=0

  HARDHAT_AUDIT_TOTAL_FINDINGS="${#HARDHAT_AUDIT_FINDING_IDS[@]}"
  HARDHAT_AUDIT_SCORE=100
  HARDHAT_AUDIT_OVERALL_SEVERITY="info"
  HARDHAT_AUDIT_COUNT_HIGH=0
  HARDHAT_AUDIT_COUNT_MEDIUM=0
  HARDHAT_AUDIT_COUNT_LOW=0
  HARDHAT_AUDIT_COUNT_INFO=0

  for ((idx = 0; idx < HARDHAT_AUDIT_TOTAL_FINDINGS; idx++)); do
    severity="${HARDHAT_AUDIT_FINDING_SEVERITIES[${idx}]}"
    penalty="$(hardhat_audit_score_penalty "${severity}")"
    HARDHAT_AUDIT_SCORE=$((HARDHAT_AUDIT_SCORE - penalty))

    case "${severity}" in
      high)
        HARDHAT_AUDIT_COUNT_HIGH=$((HARDHAT_AUDIT_COUNT_HIGH + 1))
        ;;
      medium)
        HARDHAT_AUDIT_COUNT_MEDIUM=$((HARDHAT_AUDIT_COUNT_MEDIUM + 1))
        ;;
      low)
        HARDHAT_AUDIT_COUNT_LOW=$((HARDHAT_AUDIT_COUNT_LOW + 1))
        ;;
      *)
        HARDHAT_AUDIT_COUNT_INFO=$((HARDHAT_AUDIT_COUNT_INFO + 1))
        ;;
    esac

    current_rank="$(hardhat_audit_severity_rank "${HARDHAT_AUDIT_OVERALL_SEVERITY}")"
    candidate_rank="$(hardhat_audit_severity_rank "${severity}")"
    if [[ "${candidate_rank}" -gt "${current_rank}" ]]; then
      HARDHAT_AUDIT_OVERALL_SEVERITY="${severity}"
    fi
  done

  if [[ "${HARDHAT_AUDIT_SCORE}" -lt 0 ]]; then
    HARDHAT_AUDIT_SCORE=0
  fi
}

hardhat_audit_print_human() {
  local idx=0
  local recommendation=""

  printf 'HardHat Audit Report\n'
  printf '====================\n'
  printf 'Summary\n'
  printf '- Score: %s/100\n' "${HARDHAT_AUDIT_SCORE}"
  printf '- Overall severity: %s\n' "${HARDHAT_AUDIT_OVERALL_SEVERITY}"
  printf '- Total findings: %s\n' "${HARDHAT_AUDIT_TOTAL_FINDINGS}"
  printf '- Counts: high=%s medium=%s low=%s info=%s\n' \
    "${HARDHAT_AUDIT_COUNT_HIGH}" \
    "${HARDHAT_AUDIT_COUNT_MEDIUM}" \
    "${HARDHAT_AUDIT_COUNT_LOW}" \
    "${HARDHAT_AUDIT_COUNT_INFO}"
  printf '\n'
  printf 'Signals\n'
  printf '- UFW installed: %s\n' "${HARDHAT_AUDIT_UFW_INSTALLED}"
  printf '- UFW status: %s\n' "${HARDHAT_AUDIT_UFW_ACTIVE}"
  printf '- UFW default policy: %s\n' "${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}"
  printf '- Listening sockets: %s\n' "${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT}"
  printf '- Listening ports: %s\n' "${HARDHAT_AUDIT_LISTENING_PORTS}"
  printf '- Active relevant services: %s\n' "${HARDHAT_AUDIT_ACTIVE_SERVICES}"
  printf '- SSH active: %s\n' "${HARDHAT_AUDIT_SSH_SERVICE_ACTIVE}"
  printf '- SSH PasswordAuthentication: %s\n' "${HARDHAT_AUDIT_SSH_PASSWORD_AUTH}"
  printf '- SSH PermitRootLogin: %s\n' "${HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN}"
  printf '- SSH Port: %s\n' "${HARDHAT_AUDIT_SSH_PORT}"
  printf '- Pending updates: %s\n' "${HARDHAT_AUDIT_PENDING_UPDATES}"
  printf '\n'

  if [[ "${HARDHAT_AUDIT_TOTAL_FINDINGS}" -eq 0 ]]; then
    printf 'Findings\n'
    printf '- No findings detected in this baseline audit.\n'
    return 0
  fi

  printf 'Findings\n'
  for ((idx = 0; idx < HARDHAT_AUDIT_TOTAL_FINDINGS; idx++)); do
    printf '%s) [%s] %s\n' \
      "$((idx + 1))" \
      "${HARDHAT_AUDIT_FINDING_SEVERITIES[${idx}]}" \
      "${HARDHAT_AUDIT_FINDING_TITLES[${idx}]}"
    printf '   - id: %s\n' "${HARDHAT_AUDIT_FINDING_IDS[${idx}]}"
    printf '   - description: %s\n' "${HARDHAT_AUDIT_FINDING_DESCRIPTIONS[${idx}]}"
    printf '   - recommendation: %s\n' "${HARDHAT_AUDIT_FINDING_RECOMMENDATIONS[${idx}]}"
  done

  printf '\n'
  printf 'Recommendations\n'
  declare -A seen_recommendations=()
  for recommendation in "${HARDHAT_AUDIT_FINDING_RECOMMENDATIONS[@]}"; do
    if [[ -z "${seen_recommendations[${recommendation}]:-}" ]]; then
      seen_recommendations["${recommendation}"]=1
      printf '- %s\n' "${recommendation}"
    fi
  done
}

hardhat_audit_print_json() {
  local idx=0

  printf '{'
  printf '"command":"audit",'
  printf '"summary":{'
  printf '"score":%s,' "${HARDHAT_AUDIT_SCORE}"
  printf '"severity":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_OVERALL_SEVERITY}")"
  printf '"total_findings":%s,' "${HARDHAT_AUDIT_TOTAL_FINDINGS}"
  printf '"counts":{"high":%s,"medium":%s,"low":%s,"info":%s}' \
    "${HARDHAT_AUDIT_COUNT_HIGH}" \
    "${HARDHAT_AUDIT_COUNT_MEDIUM}" \
    "${HARDHAT_AUDIT_COUNT_LOW}" \
    "${HARDHAT_AUDIT_COUNT_INFO}"
  printf '},'
  printf '"signals":{'
  printf '"ufw_installed":%s,' "${HARDHAT_AUDIT_UFW_INSTALLED}"
  printf '"ufw_status":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_UFW_ACTIVE}")"
  printf '"ufw_default_policy":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_UFW_DEFAULT_POLICY}")"
  printf '"listening_sockets":%s,' "${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT}"
  printf '"listening_ports":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_LISTENING_PORTS}")"
  printf '"active_services":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_ACTIVE_SERVICES}")"
  printf '"ssh":{"active":"%s","password_authentication":"%s","permit_root_login":"%s","port":"%s"},' \
    "$(hardhat_json_escape "${HARDHAT_AUDIT_SSH_SERVICE_ACTIVE}")" \
    "$(hardhat_json_escape "${HARDHAT_AUDIT_SSH_PASSWORD_AUTH}")" \
    "$(hardhat_json_escape "${HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN}")" \
    "$(hardhat_json_escape "${HARDHAT_AUDIT_SSH_PORT}")"
  printf '"pending_updates":%s' "${HARDHAT_AUDIT_PENDING_UPDATES}"
  printf '},'
  printf '"findings":['
  for ((idx = 0; idx < HARDHAT_AUDIT_TOTAL_FINDINGS; idx++)); do
    if [[ "${idx}" -gt 0 ]]; then
      printf ','
    fi
    printf '{'
    printf '"id":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_FINDING_IDS[${idx}]}")"
    printf '"severity":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_FINDING_SEVERITIES[${idx}]}")"
    printf '"title":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_FINDING_TITLES[${idx}]}")"
    printf '"description":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_FINDING_DESCRIPTIONS[${idx}]}")"
    printf '"recommendation":"%s"' "$(hardhat_json_escape "${HARDHAT_AUDIT_FINDING_RECOMMENDATIONS[${idx}]}")"
    printf '}'
  done
  printf ']'
  printf '}\n'
}

hardhat_module_audit_run() {
  hardhat_log_info "Running HardHat baseline audit."

  hardhat_audit_reset_state
  hardhat_audit_collect
  hardhat_audit_calculate_summary

  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    hardhat_audit_print_json
    return 0
  fi

  hardhat_audit_print_human
}