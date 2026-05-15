#!/usr/bin/env bash

HARDHAT_AUDIT_FINDINGS=()
HARDHAT_AUDIT_NOTES=()
HARDHAT_AUDIT_SCORE=100
HARDHAT_AUDIT_SEVERITY="none"
HARDHAT_AUDIT_SUMMARY="baseline security audit completed"
HARDHAT_AUDIT_RECOMMENDATIONS=()

hardhat_audit_is_spanish() {
  [[ "${HARDHAT_LANG:-en}" == "es" ]]
}

hardhat_audit_default_summary() {
  if hardhat_audit_is_spanish; then
    printf 'auditoria de seguridad de linea base completada'
    return 0
  fi

  printf 'baseline security audit completed'
}

hardhat_module_audit_usage() {
  if hardhat_audit_is_spanish; then
    cat <<'EOF'
Uso:
  hardhat audit [--json]

Descripcion:
  Ejecuta validaciones de linea base de firewall, puertos, servicios, SSH y actualizaciones,
  y reporta score, severidad, hallazgos y recomendaciones.
EOF
    return 0
  fi

  cat <<'EOF'
Usage:
  hardhat audit [--json]

Description:
  Runs baseline checks for firewall, ports, services, SSH and updates,
  then reports score, severity, findings and recommendations.
EOF
}

hardhat_audit_reset_state() {
  HARDHAT_AUDIT_FINDINGS=()
  HARDHAT_AUDIT_NOTES=()
  HARDHAT_AUDIT_SCORE=100
  HARDHAT_AUDIT_SEVERITY="none"
  HARDHAT_AUDIT_SUMMARY="$(hardhat_audit_default_summary)"
  HARDHAT_AUDIT_RECOMMENDATIONS=()
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

hardhat_audit_collect_recommendations() {
  HARDHAT_AUDIT_RECOMMENDATIONS=()
  local item recommendation
  local -A seen=()

  for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
    IFS='|' read -r _ _ _ _ recommendation <<<"${item}"
    if [[ -z "${recommendation}" ]]; then
      continue
    fi
    if [[ -n "${seen["${recommendation}"]+x}" ]]; then
      continue
    fi
    HARDHAT_AUDIT_RECOMMENDATIONS+=("${recommendation}")
    seen["${recommendation}"]=1
  done
}

hardhat_audit_generated_at_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown'
}

hardhat_audit_collect() {
  if hardhat_audit_is_spanish; then
    hardhat_audit_add_note "Ejecutando validaciones de linea base de firewall, puertos, servicios, SSH y actualizaciones."

    hardhat_log_info "Auditoria: revisando estado de firewall..."
    hardhat_module_firewall_collect_audit

    hardhat_log_info "Auditoria: revisando puertos en escucha..."
    hardhat_module_ports_collect_audit

    hardhat_log_info "Auditoria: revisando servicios activos..."
    hardhat_module_services_collect_audit

    hardhat_log_info "Auditoria: revisando configuracion basica de SSH..."
    hardhat_module_ssh_audit_collect

    hardhat_log_info "Auditoria: revisando updates pendientes..."
    hardhat_module_updates_collect_audit
    return 0
  fi

  hardhat_audit_add_note "Running baseline checks for firewall, ports, services, SSH and updates."

  hardhat_log_info "Audit: checking firewall state..."
  hardhat_module_firewall_collect_audit

  hardhat_log_info "Audit: checking listening ports..."
  hardhat_module_ports_collect_audit

  hardhat_log_info "Audit: checking active services..."
  hardhat_module_services_collect_audit

  hardhat_log_info "Audit: checking SSH basic settings..."
  hardhat_module_ssh_audit_collect

  hardhat_log_info "Audit: checking pending updates..."
  hardhat_module_updates_collect_audit
}

hardhat_audit_render_human() {
  local findings_count="${#HARDHAT_AUDIT_FINDINGS[@]}"

  if hardhat_audit_is_spanish; then
    printf 'Reporte de Auditoria HardHat\n'
    printf 'Resumen: %s\n' "${HARDHAT_AUDIT_SUMMARY}"
    printf 'Score: %s/100\n' "${HARDHAT_AUDIT_SCORE}"
    printf 'Severidad general: %s\n' "${HARDHAT_AUDIT_SEVERITY}"
    printf 'Hallazgos: %s\n\n' "${findings_count}"

    local note
    for note in "${HARDHAT_AUDIT_NOTES[@]}"; do
      printf -- '- %s\n' "${note}"
    done

    if ((findings_count == 0)); then
      printf '\nNo se detectaron hallazgos en esta auditoria baseline.\n'
      return 0
    fi

    printf '\nHallazgos detallados:\n'
    local idx=1
    local item id severity title description recommendation
    for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
      IFS='|' read -r id severity title description recommendation <<<"${item}"
      printf '%s. [%s] %s (%s)\n' "${idx}" "${severity}" "${title}" "${id}"
      printf '   Descripcion: %s\n' "${description}"
      printf '   Recomendacion: %s\n' "${recommendation}"
      idx=$((idx + 1))
    done

    if ((${#HARDHAT_AUDIT_RECOMMENDATIONS[@]} > 0)); then
      printf '\nRecomendaciones principales:\n'
      local rec
      for rec in "${HARDHAT_AUDIT_RECOMMENDATIONS[@]}"; do
        printf -- '- %s\n' "${rec}"
      done
    fi
    return 0
  fi

  printf 'HardHat Audit Report\n'
  printf 'Summary: %s\n' "${HARDHAT_AUDIT_SUMMARY}"
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

  if ((${#HARDHAT_AUDIT_RECOMMENDATIONS[@]} > 0)); then
    printf '\nTop recommendations:\n'
    local rec
    for rec in "${HARDHAT_AUDIT_RECOMMENDATIONS[@]}"; do
      printf -- '- %s\n' "${rec}"
    done
  fi
}

hardhat_audit_render_json() {
  local distro_id
  local generated_at
  local findings_count="${#HARDHAT_AUDIT_FINDINGS[@]}"
  distro_id="$(hardhat_detect_distro_id || printf 'unknown')"
  generated_at="$(hardhat_audit_generated_at_utc)"

  printf '{'
  printf '"metadata":{'
  printf '"tool":"hardhat",'
  printf '"version":"%s",' "$(hardhat_json_escape "${HARDHAT_VERSION:-unknown}")"
  printf '"command":"audit",'
  printf '"generated_at":'
  hardhat_json_nullable_string "${generated_at}"
  printf '},'

  printf '"system":{'
  printf '"distro":'
  hardhat_json_nullable_string "${distro_id}"
  printf '},'

  printf '"summary":{'
  printf '"text":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_SUMMARY}")"
  printf '"score":%s,' "${HARDHAT_AUDIT_SCORE}"
  printf '"severity":"%s",' "$(hardhat_json_escape "${HARDHAT_AUDIT_SEVERITY}")"
  printf '"findings_count":%s' "${findings_count}"
  printf '},'

  printf '"notes":'
  hardhat_json_print_string_array "${HARDHAT_AUDIT_NOTES[@]}"
  printf ','

  printf '"findings":['
  local note_idx=0
  local item id severity title description recommendation
  for item in "${HARDHAT_AUDIT_FINDINGS[@]}"; do
    IFS='|' read -r id severity title description recommendation <<<"${item}"
    if ((note_idx > 0)); then
      printf ','
    fi
    printf '{'
    printf '"id":"%s",' "$(hardhat_json_escape "${id}")"
    printf '"severity":"%s",' "$(hardhat_json_escape "${severity}")"
    printf '"title":"%s",' "$(hardhat_json_escape "${title}")"
    printf '"description":"%s",' "$(hardhat_json_escape "${description}")"
    printf '"recommendation":"%s"' "$(hardhat_json_escape "${recommendation}")"
    printf '}'
    note_idx=$((note_idx + 1))
  done
  printf '],'

  printf '"recommendations":'
  hardhat_json_print_string_array "${HARDHAT_AUDIT_RECOMMENDATIONS[@]}"
  printf '}'
  printf '\n'
}

hardhat_module_audit_run() {
  local arg="${1:-}"
  if [[ "${arg}" == "help" ]]; then
    hardhat_module_audit_usage
    return 0
  fi

  hardhat_audit_reset_state
  hardhat_audit_collect
  hardhat_audit_calculate_score
  hardhat_audit_collect_recommendations

  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    hardhat_audit_render_json
    return 0
  fi

  hardhat_audit_render_human
}