#!/usr/bin/env bash

HARDHAT_UFW_INSTALLED=0
HARDHAT_UFW_ACTIVE="unknown"
HARDHAT_UFW_DEFAULT_POLICY="unknown"
HARDHAT_UFW_RULES=()
HARDHAT_FIREWALL_FINDINGS=()
HARDHAT_FIREWALL_NOTES=()
HARDHAT_FIREWALL_RECOMMENDATIONS=()
HARDHAT_FIREWALL_SEVERITY="none"
HARDHAT_FIREWALL_PLAN=()
HARDHAT_FIREWALL_SSH_ACTIVE=0
HARDHAT_FIREWALL_SSH_PORT="unknown"
HARDHAT_FIREWALL_SSH_RULE_NEEDED=0
HARDHAT_FIREWALL_BACKEND_MISSING=0
HARDHAT_FIREWALL_INSTALL_RECOMMENDED=0
HARDHAT_FIREWALL_INSTALL_SUPPORTED=0
HARDHAT_FIREWALL_INSTALL_METHOD="unknown"
HARDHAT_FIREWALL_RULES_SOURCE="unknown"
HARDHAT_FIREWALL_LOG_FILE="/var/log/hardhat.log"
HARDHAT_FIREWALL_APPLY_DRY_RUN=0
HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_BEFORE=0
HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER=0
HARDHAT_FIREWALL_APPLY_UFW_INSTALL_ATTEMPTED=0
HARDHAT_FIREWALL_APPLY_UFW_INSTALL_SUCCEEDED=0
HARDHAT_FIREWALL_APPLY_BACKUPS_REQUIRED=0
HARDHAT_FIREWALL_APPLY_BACKUPS_CREATED_COUNT=0
HARDHAT_FIREWALL_APPLY_ATTEMPTED=0
HARDHAT_FIREWALL_APPLY_SUCCEEDED=0
HARDHAT_FIREWALL_APPLY_VALIDATION_SUCCEEDED=0
HARDHAT_FIREWALL_APPLY_VALIDATION_RESULT="unknown"
HARDHAT_FIREWALL_APPLY_STATUS="unknown"
HARDHAT_FIREWALL_APPLY_MESSAGE=""
HARDHAT_FIREWALL_APPLY_NOTES=()
HARDHAT_FIREWALL_APPLY_EXPECT_SSH_RULE=0
HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT="unknown"

hardhat_module_firewall_usage() {
  if hardhat_firewall_is_spanish; then
    cat <<'EOF'
HardHat firewall - Gestion de firewall

Uso:
  hardhat firewall <subcomando> [opciones]

Subcomandos:
  audit               Audita estado y baseline de UFW
  apply               Aplica baseline de UFW (cambios en sistema)
  help                Muestra esta ayuda

Opciones globales frecuentes:
  --json              Salida JSON (especialmente util con audit)
  --dry-run           Simula acciones sin aplicar cambios
  --yes               Omite confirmaciones interactivas

Ejemplos:
  hardhat firewall audit
  hardhat firewall audit --json
  hardhat firewall apply --dry-run
  hardhat firewall apply --yes

Nota:
  Si UFW no esta instalado, apply puede guiar su instalacion antes de aplicar la linea base.
EOF
    return 0
  fi

  cat <<'EOF'
HardHat firewall - Firewall management

Usage:
  hardhat firewall <subcommand> [options]

Subcommands:
  audit               Audit UFW state and baseline
  apply               Apply UFW baseline (changes system state)
  help                Show this help

Common global options:
  --json              JSON output (especially useful with audit)
  --dry-run           Simulate actions without applying changes
  --yes               Skip interactive confirmations

Examples:
  hardhat firewall audit
  hardhat firewall audit --json
  hardhat firewall apply --dry-run
  hardhat firewall apply --yes

Note:
  If UFW is missing, apply can guide installation before baseline configuration.
EOF
}

hardhat_module_firewall_audit_usage() {
  if hardhat_firewall_is_spanish; then
    cat <<'EOF'
HardHat firewall audit - Auditoria de UFW

Uso:
  hardhat firewall audit [opciones]

Opciones:
  -h, --help          Muestra esta ayuda
  --json              Emite salida JSON en stdout

Ejemplos:
  hardhat firewall audit
  hardhat firewall audit --json
EOF
    return 0
  fi

  cat <<'EOF'
HardHat firewall audit - UFW audit

Usage:
  hardhat firewall audit [options]

Options:
  -h, --help          Show this help
  --json              Emit JSON output on stdout

Examples:
  hardhat firewall audit
  hardhat firewall audit --json
EOF
}

hardhat_module_firewall_apply_usage() {
  if hardhat_firewall_is_spanish; then
    cat <<'EOF'
HardHat firewall apply - Aplicacion de baseline

Uso:
  hardhat firewall apply [opciones]

Opciones:
  -h, --help          Muestra esta ayuda
  --json              Emite resumen JSON final
  --dry-run           Simula sin aplicar cambios
  --yes               Omite confirmaciones

Ejemplos:
  hardhat firewall apply --dry-run
  hardhat firewall apply --yes

Notas:
  - Puede requerir privilegios elevados para modificar UFW.
  - Si UFW no existe, puede ofrecer instalacion guiada.
  - No hay rollback automatico en esta fase.
EOF
    return 0
  fi

  cat <<'EOF'
HardHat firewall apply - Baseline apply

Usage:
  hardhat firewall apply [options]

Options:
  -h, --help          Show this help
  --json              Emit final JSON summary
  --dry-run           Simulate without applying changes
  --yes               Skip confirmations

Examples:
  hardhat firewall apply --dry-run
  hardhat firewall apply --yes

Notes:
  - Elevated privileges may be required to modify UFW.
  - If UFW is missing, guided installation may be offered.
  - Automatic rollback is not available in this phase.
EOF
}

hardhat_module_firewall_validate_subcommand_args() {
  local subcommand="$1"
  shift || true

  local arg
  for arg in "$@"; do
    case "${subcommand}:${arg}" in
      audit:-h|audit:--help|audit:help)
        hardhat_module_firewall_audit_usage
        return 2
        ;;
      audit:--json)
        ;;
      apply:-h|apply:--help|apply:help)
        hardhat_module_firewall_apply_usage
        return 2
        ;;
      apply:--dry-run|apply:--yes)
        ;;
      apply:--json)
        ;;
      *)
        if hardhat_firewall_is_spanish; then
          hardhat_log_error "Argumento no valido para firewall ${subcommand}: ${arg}"
          hardhat_log_info "Usa 'hardhat firewall ${subcommand} --help' para ver uso."
        else
          hardhat_log_error "Invalid argument for firewall ${subcommand}: ${arg}"
          hardhat_log_info "Use 'hardhat firewall ${subcommand} --help' for usage."
        fi
        return 1
        ;;
    esac
  done

  return 0
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
  HARDHAT_FIREWALL_PLAN=()
  HARDHAT_FIREWALL_SSH_ACTIVE=0
  HARDHAT_FIREWALL_SSH_PORT="unknown"
  HARDHAT_FIREWALL_SSH_RULE_NEEDED=0
  HARDHAT_FIREWALL_BACKEND_MISSING=0
  HARDHAT_FIREWALL_INSTALL_RECOMMENDED=0
  HARDHAT_FIREWALL_INSTALL_SUPPORTED=0
  HARDHAT_FIREWALL_INSTALL_METHOD="unknown"
  HARDHAT_FIREWALL_RULES_SOURCE="unknown"
}

hardhat_firewall_apply_reset_state() {
  HARDHAT_FIREWALL_APPLY_DRY_RUN=0
  HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_BEFORE=0
  HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER=0
  HARDHAT_FIREWALL_APPLY_UFW_INSTALL_ATTEMPTED=0
  HARDHAT_FIREWALL_APPLY_UFW_INSTALL_SUCCEEDED=0
  HARDHAT_FIREWALL_APPLY_BACKUPS_REQUIRED=0
  HARDHAT_FIREWALL_APPLY_BACKUPS_CREATED_COUNT=0
  HARDHAT_FIREWALL_APPLY_ATTEMPTED=0
  HARDHAT_FIREWALL_APPLY_SUCCEEDED=0
  HARDHAT_FIREWALL_APPLY_VALIDATION_SUCCEEDED=0
  HARDHAT_FIREWALL_APPLY_VALIDATION_RESULT="unknown"
  HARDHAT_FIREWALL_APPLY_STATUS="unknown"
  HARDHAT_FIREWALL_APPLY_MESSAGE=""
  HARDHAT_FIREWALL_APPLY_NOTES=()
  HARDHAT_FIREWALL_APPLY_EXPECT_SSH_RULE=0
  HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT="unknown"
}

hardhat_firewall_apply_add_note() {
  HARDHAT_FIREWALL_APPLY_NOTES+=("$*")
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

hardhat_firewall_is_spanish() {
  [[ "${HARDHAT_LANG:-en}" == "es" ]]
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

hardhat_firewall_has_allow_rule_for_port() {
  local port="$1"

  if [[ -z "${port}" || "${port}" == "unknown" ]]; then
    return 1
  fi

  local rules_text
  rules_text="$(printf '%s\n' "${HARDHAT_UFW_RULES[@]}")"
  grep -qiE "(^|[[:space:]])${port}(/tcp)?[[:space:]].*(ALLOW)" <<<"${rules_text}"
}

hardhat_firewall_analyze_rules() {
  if ((${#HARDHAT_UFW_RULES[@]} == 0)); then
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "No se detectaron reglas explicitas de UFW o no se pudieron parsear."
    else
      hardhat_firewall_add_note "No explicit UFW rules detected or they could not be parsed."
    fi
    return 0
  fi

  if hardhat_firewall_is_spanish; then
    hardhat_firewall_add_note "Reglas UFW detectadas: ${#HARDHAT_UFW_RULES[@]}."
  else
    hardhat_firewall_add_note "UFW rules detected: ${#HARDHAT_UFW_RULES[@]}."
  fi

  local rules_text
  rules_text="$(printf '%s\n' "${HARDHAT_UFW_RULES[@]}")"

  if grep -qiE 'ALLOW IN[[:space:]]+Anywhere( |$)|ALLOW[[:space:]]+Anywhere( |$)' <<<"${rules_text}"; then
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_finding \
        "firewall.ufw.allow_anywhere" \
        "medium" \
        "Regla allow amplia detectada" \
        "Al menos una regla UFW permite trafico entrante desde Anywhere sin restriccion clara de origen." \
        "Restringe reglas allow a rangos de origen confiables y solo puertos necesarios."
    else
      hardhat_firewall_add_finding \
        "firewall.ufw.allow_anywhere" \
        "medium" \
        "Broad allow rule detected" \
        "At least one UFW rule allows inbound traffic from Anywhere without clear source restriction." \
        "Restrict allow rules to trusted source ranges and only required ports."
    fi
  fi

  if grep -qiE '(23|3389)(/tcp|/udp)?[[:space:]].*(ALLOW).*(Anywhere)' <<<"${rules_text}"; then
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_finding \
        "firewall.ufw.risky_port_anywhere" \
        "high" \
        "Regla de acceso remoto riesgosa expuesta" \
        "Un puerto sensible (Telnet o RDP) parece permitido desde Anywhere." \
        "Cierra puertos remotos riesgosos o restringelos a redes de origen confiables."
    else
      hardhat_firewall_add_finding \
        "firewall.ufw.risky_port_anywhere" \
        "high" \
        "Risky remote-access rule exposed" \
        "A sensitive port (Telnet or RDP) appears allowed from Anywhere." \
        "Close risky remote-access ports or restrict them to trusted source networks."
    fi
  fi
}

hardhat_firewall_generated_at_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf 'unknown'
}

hardhat_firewall_apply_render_json() {
  local generated_at
  generated_at="$(hardhat_firewall_generated_at_utc)"

  printf '{'
  printf '"metadata":{'
  printf '"tool":"hardhat",'
  printf '"version":"%s",' "$(hardhat_json_escape "${HARDHAT_VERSION:-unknown}")"
  printf '"command":"firewall apply",'
  printf '"generated_at":'
  hardhat_json_nullable_string "${generated_at}"
  printf '},'

  printf '"apply":{'
  printf '"dry_run":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_DRY_RUN}" -eq 1 ]] && printf true || printf false )"
  printf '"ufw_installed_before":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_BEFORE}" -eq 1 ]] && printf true || printf false )"
  printf '"ufw_installed_after":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER}" -eq 1 ]] && printf true || printf false )"
  printf '"ufw_install_attempted":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_UFW_INSTALL_ATTEMPTED}" -eq 1 ]] && printf true || printf false )"
  printf '"ufw_install_succeeded":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_UFW_INSTALL_SUCCEEDED}" -eq 1 ]] && printf true || printf false )"
  printf '"backups_required":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_BACKUPS_REQUIRED}" -eq 1 ]] && printf true || printf false )"
  printf '"backups_created_count":%s,' "${HARDHAT_FIREWALL_APPLY_BACKUPS_CREATED_COUNT}"
  printf '"apply_attempted":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_ATTEMPTED}" -eq 1 ]] && printf true || printf false )"
  printf '"apply_succeeded":%s,' "$( [[ "${HARDHAT_FIREWALL_APPLY_SUCCEEDED}" -eq 1 ]] && printf true || printf false )"
  printf '"validation_succeeded":%s' "$( [[ "${HARDHAT_FIREWALL_APPLY_VALIDATION_SUCCEEDED}" -eq 1 ]] && printf true || printf false )"
  printf '},'

  printf '"firewall":{'
  printf '"active":'
  hardhat_json_nullable_string "${HARDHAT_UFW_ACTIVE}"
  printf ','
  printf '"default_policy":'
  hardhat_json_nullable_string "${HARDHAT_UFW_DEFAULT_POLICY}"
  printf ','
  printf '"sshd_active":%s,' "$( [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && printf true || printf false )"
  printf '"ssh_port":'
  hardhat_json_nullable_string "${HARDHAT_FIREWALL_SSH_PORT}"
  printf ','
  printf '"ssh_rule_needed":%s' "$( [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]] && printf true || printf false )"
  printf '},'

  printf '"summary":{'
  printf '"status":"%s",' "$(hardhat_json_escape "${HARDHAT_FIREWALL_APPLY_STATUS}")"
  printf '"message":"%s"' "$(hardhat_json_escape "${HARDHAT_FIREWALL_APPLY_MESSAGE}")"
  printf '},'

  printf '"notes":'
  hardhat_json_print_string_array "${HARDHAT_FIREWALL_APPLY_NOTES[@]}"
  printf ','

  printf '"recommendations":'
  hardhat_json_print_string_array "${HARDHAT_FIREWALL_RECOMMENDATIONS[@]}"
  printf '}'
  printf '\n'
}

hardhat_firewall_apply_finish() {
  local status="$1"
  local message="$2"
  local exit_code="$3"

  HARDHAT_FIREWALL_APPLY_STATUS="${status}"
  HARDHAT_FIREWALL_APPLY_MESSAGE="${message}"

  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -eq 1 ]]; then
    hardhat_firewall_apply_render_json
  fi

  return "${exit_code}"
}

hardhat_firewall_write_log() {
  local event="$1"
  local line
  line="$(hardhat_firewall_generated_at_utc) firewall.apply ${event}"
  if ! printf '%s\n' "${line}" | hardhat_sudo_run tee -a "${HARDHAT_FIREWALL_LOG_FILE}" >/dev/null; then
    hardhat_log_warn "Could not write audit log to ${HARDHAT_FIREWALL_LOG_FILE}."
  fi
}

hardhat_firewall_is_sshd_active() {
  if ! command -v systemctl >/dev/null 2>&1; then
    return 1
  fi
  systemctl is-active --quiet sshd
}

hardhat_firewall_detect_ssh_port() {
  local config_files=()
  local file
  local line
  local value=""

  if [[ -f /etc/ssh/sshd_config ]]; then
    config_files+=("/etc/ssh/sshd_config")
  fi

  if [[ -d /etc/ssh/sshd_config.d ]]; then
    while IFS= read -r file; do
      config_files+=("${file}")
    done < <(find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' 2>/dev/null | sort)
  fi

  for file in "${config_files[@]}"; do
    while IFS= read -r line; do
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      if [[ "${line}" =~ ^[[:space:]]*Port[[:space:]]+([0-9]+) ]]; then
        value="${BASH_REMATCH[1]}"
      fi
    done <"${file}"
  done

  if [[ -n "${value}" ]]; then
    printf '%s' "${value}"
    return 0
  fi

  printf '%s' "22"
}

hardhat_firewall_detect_ssh_context() {
  HARDHAT_FIREWALL_SSH_ACTIVE=0
  HARDHAT_FIREWALL_SSH_PORT="unknown"
  HARDHAT_FIREWALL_SSH_RULE_NEEDED=0

  if hardhat_firewall_is_sshd_active; then
    HARDHAT_FIREWALL_SSH_ACTIVE=1
    HARDHAT_FIREWALL_SSH_PORT="$(hardhat_firewall_detect_ssh_port)"
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "sshd esta activo. Puerto SSH detectado: ${HARDHAT_FIREWALL_SSH_PORT}."
    else
      hardhat_firewall_add_note "sshd is active. Detected SSH port: ${HARDHAT_FIREWALL_SSH_PORT}."
    fi

    local rules_text
    rules_text="$(printf '%s\n' "${HARDHAT_UFW_RULES[@]}")"
    if grep -qiE "${HARDHAT_FIREWALL_SSH_PORT}(/tcp)?[[:space:]].*(ALLOW)" <<<"${rules_text}"; then
      HARDHAT_FIREWALL_SSH_RULE_NEEDED=0
      if hardhat_firewall_is_spanish; then
        hardhat_firewall_add_note "Parece existir una regla allow para el puerto SSH ${HARDHAT_FIREWALL_SSH_PORT}."
      else
        hardhat_firewall_add_note "An allow rule for SSH port ${HARDHAT_FIREWALL_SSH_PORT} appears to exist."
      fi
    else
      HARDHAT_FIREWALL_SSH_RULE_NEEDED=1
      if hardhat_firewall_is_spanish; then
        hardhat_firewall_add_note "No se encontro una regla allow explicita para el puerto SSH ${HARDHAT_FIREWALL_SSH_PORT}."
        hardhat_firewall_add_recommendation "Permite el puerto SSH ${HARDHAT_FIREWALL_SSH_PORT}/tcp antes de habilitar defaults estrictos."
      else
        hardhat_firewall_add_note "No explicit allow rule found for SSH port ${HARDHAT_FIREWALL_SSH_PORT}."
        hardhat_firewall_add_recommendation "Allow SSH port ${HARDHAT_FIREWALL_SSH_PORT}/tcp before enabling strict defaults."
      fi
    fi
  else
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "sshd no esta activo."
    else
      hardhat_firewall_add_note "sshd is not active."
    fi
  fi
}

hardhat_firewall_validate_environment() {
  if ! hardhat_detect_arch_linux; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "HardHat firewall apply actualmente solo soporta Arch Linux."
    else
      hardhat_log_error "HardHat firewall apply currently supports only Arch Linux."
    fi
    return 1
  fi

  if ! hardhat_require_elevated_or_sudo; then
    return 1
  fi

  return 0
}

hardhat_firewall_report_missing_backend() {
  if hardhat_firewall_is_spanish; then
    hardhat_log_warn "UFW no esta instalado. No hay backend de firewall soportado configurado para este MVP."
    hardhat_log_warn "Este sistema no tiene actualmente una linea base de firewall de HardHat y puede estar expuesto a trafico entrante."
    hardhat_log_info "HardHat puede instalar UFW y aplicar ahora una linea base segura."
    return 0
  fi

  hardhat_log_warn "UFW is not installed. No supported firewall backend is configured for this MVP."
  hardhat_log_warn "This system currently has no HardHat firewall baseline and may be exposed to inbound traffic."
  hardhat_log_info "HardHat can install UFW and apply a safe baseline now."
}

hardhat_firewall_install_ufw() {
  if command -v ufw >/dev/null 2>&1; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_info "UFW ya esta instalado."
    else
      hardhat_log_info "UFW is already installed."
    fi
    return 0
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "pacman no esta disponible; no se puede instalar UFW automaticamente."
    else
      hardhat_log_error "pacman is not available; cannot install UFW automatically."
    fi
    return 1
  fi

  local -a pacman_args=(-S --needed ufw)
  if [[ "${HARDHAT_ASSUME_YES:-0}" -eq 1 ]]; then
    pacman_args=(-S --needed --noconfirm ufw)
  fi

  if hardhat_firewall_is_spanish; then
    hardhat_log_info "Instalando UFW con pacman..."
  else
    hardhat_log_info "Installing UFW with pacman..."
  fi
  if ! hardhat_sudo_run pacman "${pacman_args[@]}"; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Fallo la instalacion de UFW via pacman."
    else
      hardhat_log_error "Failed to install UFW via pacman."
    fi
    return 1
  fi

  if ! command -v ufw >/dev/null 2>&1; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "El comando de instalacion de UFW finalizo, pero ufw sigue sin estar disponible en PATH."
    else
      hardhat_log_error "UFW installation command completed but ufw is still unavailable in PATH."
    fi
    return 1
  fi

  if hardhat_firewall_is_spanish; then
    hardhat_log_success "UFW se instalo correctamente."
  else
    hardhat_log_success "UFW installed successfully."
  fi
  return 0
}

hardhat_firewall_build_apply_plan() {
  HARDHAT_FIREWALL_PLAN=()

  local use_es=0
  if hardhat_firewall_is_spanish; then
    use_es=1
  fi

  if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      HARDHAT_FIREWALL_PLAN+=("Instalar paquete UFW con pacman.")
      HARDHAT_FIREWALL_PLAN+=("Recolectar estado actual de UFW despues de la instalacion.")
    else
      HARDHAT_FIREWALL_PLAN+=("Install UFW package with pacman.")
      HARDHAT_FIREWALL_PLAN+=("Collect current UFW status after installation.")
    fi
  fi

  if [[ "${use_es}" -eq 1 ]]; then
    HARDHAT_FIREWALL_PLAN+=("Crear backups de archivos de configuracion de UFW antes de aplicar cambios de politica.")
    HARDHAT_FIREWALL_PLAN+=("Configurar politica de entrada por defecto de UFW en deny.")
    HARDHAT_FIREWALL_PLAN+=("Configurar politica de salida por defecto de UFW en allow.")
  else
    HARDHAT_FIREWALL_PLAN+=("Create backups of UFW configuration files before applying policy changes.")
    HARDHAT_FIREWALL_PLAN+=("Set UFW default incoming policy to deny.")
    HARDHAT_FIREWALL_PLAN+=("Set UFW default outgoing policy to allow.")
  fi

  if [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      HARDHAT_FIREWALL_PLAN+=("Agregar regla allow de UFW para SSH en el puerto ${HARDHAT_FIREWALL_SSH_PORT}/tcp.")
    else
      HARDHAT_FIREWALL_PLAN+=("Add UFW allow rule for SSH on port ${HARDHAT_FIREWALL_SSH_PORT}/tcp.")
    fi
  fi

  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      HARDHAT_FIREWALL_PLAN+=("Habilitar UFW para aplicar reglas de firewall.")
    else
      HARDHAT_FIREWALL_PLAN+=("Enable UFW to enforce firewall rules.")
    fi
  else
    if [[ "${use_es}" -eq 1 ]]; then
      HARDHAT_FIREWALL_PLAN+=("UFW ya esta activo; refrescar defaults de linea base sin deshabilitar firewall.")
    else
      HARDHAT_FIREWALL_PLAN+=("UFW already active; refresh baseline defaults without disabling firewall.")
    fi
  fi
}

hardhat_firewall_render_apply_plan() {
  if hardhat_firewall_is_spanish; then
    local installed_text="no"
    local active_text="${HARDHAT_UFW_ACTIVE}"
    local default_policy_text="${HARDHAT_UFW_DEFAULT_POLICY}"

    if [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]]; then
      installed_text="si"
    fi

    if [[ "${active_text}" == "unknown" ]]; then
      active_text="desconocido"
    fi

    if [[ "${default_policy_text}" == "unknown" ]]; then
      default_policy_text="desconocida"
    fi

    printf 'Plan de Aplicacion de Firewall HardHat\n'
    printf 'Backend objetivo: UFW\n'
    printf 'Estado actual: instalado=%s activo=%s politica_por_defecto=%s\n\n' \
      "${installed_text}" \
      "${active_text}" \
      "${default_policy_text}"

    local idx=1
    local step
    for step in "${HARDHAT_FIREWALL_PLAN[@]}"; do
      printf '%s. %s\n' "${idx}" "${step}"
      idx=$((idx + 1))
    done

    printf '\nAvisos de seguridad:\n'
    printf -- '- Los archivos de configuracion existentes de UFW se respaldan antes de aplicar cambios de politica.\n'
    printf -- '- En una instalacion inicial de UFW, apply continua si aun no existen archivos de configuracion de UFW.\n'
    printf -- '- Si un backup requerido falla, HardHat no aplica cambios de politica.\n'
    printf -- '- No hay rollback automatico en esta fase.\n'
    return 0
  fi

  printf 'HardHat Firewall Apply Plan\n'
  printf 'Target backend: UFW\n'
  printf 'Current status: installed=%s active=%s default_policy=%s\n\n' \
    "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf yes || printf no )" \
    "${HARDHAT_UFW_ACTIVE}" \
    "${HARDHAT_UFW_DEFAULT_POLICY}"

  local idx=1
  local step
  for step in "${HARDHAT_FIREWALL_PLAN[@]}"; do
    printf '%s. %s\n' "${idx}" "${step}"
    idx=$((idx + 1))
  done

  printf '\nSafety notices:\n'
  printf -- '- Existing UFW configuration files are backed up before policy changes.\n'
  printf -- '- On first-time UFW install, apply continues if no UFW config files exist yet.\n'
  printf -- '- If a required backup fails, HardHat does not apply policy changes.\n'
  printf -- '- Automatic rollback is not available in this phase.\n'
}

hardhat_firewall_create_backups_or_fail() {
  # Policy:
  # - require_existing_files=1: UFW existed before apply; at least one existing
  #   config file must be backed up successfully or apply is aborted.
  # - require_existing_files=0: first-time UFW install path; continue if no
  #   files exist yet, but back up anything that already exists.
  local require_existing_files="${1:-1}"
  local backup_dir="/var/backups/hardhat/firewall"
  local -a candidates=(
    "/etc/ufw/ufw.conf"
    "/etc/default/ufw"
    "/etc/ufw/user.rules"
    "/etc/ufw/user6.rules"
    "/etc/ufw/before.rules"
    "/etc/ufw/before6.rules"
  )

  local source_file
  local existing_count=0
  local backup_count=0

  HARDHAT_FIREWALL_APPLY_BACKUPS_CREATED_COUNT=0

  for source_file in "${candidates[@]}"; do
    if [[ ! -f "${source_file}" ]]; then
      continue
    fi
    existing_count=$((existing_count + 1))

    if ! hardhat_backup_file "${source_file}" "${backup_dir}"; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "Fallo el backup de ${source_file}; abortando apply."
      else
        hardhat_log_error "Backup failed for ${source_file}; aborting apply."
      fi
      return 1
    fi
    backup_count=$((backup_count + 1))
    HARDHAT_FIREWALL_APPLY_BACKUPS_CREATED_COUNT="${backup_count}"
  done

  if ((existing_count == 0)); then
    if [[ "${require_existing_files}" -eq 1 ]]; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "UFW parece preexistente, pero no se encontro ningun archivo de configuracion para backup; se rechaza aplicar cambios."
      else
        hardhat_log_error "UFW appears pre-existing but no configuration file was found for backup; refusing to apply changes."
      fi
      return 1
    fi

    if hardhat_firewall_is_spanish; then
      hardhat_log_warn "No se encontraron archivos de configuracion de UFW para respaldar despues de la instalacion. Continuando con apply inicial de linea base."
    else
      hardhat_log_warn "No UFW configuration files found to back up after installation. Continuing with initial baseline apply."
    fi
    return 0
  fi

  if hardhat_firewall_is_spanish; then
    hardhat_log_success "Etapa de backup completada (${backup_count} archivo(s))."
  else
    hardhat_log_success "Backup stage completed (${backup_count} file(s))."
  fi
  return 0
}

hardhat_firewall_apply_actions() {
  if ! hardhat_sudo_run ufw --force default deny incoming; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Fallo al configurar la politica de entrada por defecto de UFW."
    else
      hardhat_log_error "Failed to set UFW default incoming policy."
    fi
    return 1
  fi

  if ! hardhat_sudo_run ufw --force default allow outgoing; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Fallo al configurar la politica de salida por defecto de UFW."
    else
      hardhat_log_error "Failed to set UFW default outgoing policy."
    fi
    return 1
  fi

  if [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]]; then
    if ! hardhat_sudo_run ufw allow "${HARDHAT_FIREWALL_SSH_PORT}/tcp"; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "Fallo al agregar regla allow de SSH para el puerto ${HARDHAT_FIREWALL_SSH_PORT}/tcp."
      else
        hardhat_log_error "Failed to add SSH allow rule for port ${HARDHAT_FIREWALL_SSH_PORT}/tcp."
      fi
      return 1
    fi
  fi

  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    if ! hardhat_sudo_run ufw --force enable; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "Fallo al habilitar UFW."
      else
        hardhat_log_error "Failed to enable UFW."
      fi
      return 1
    fi
  fi

  return 0
}

hardhat_firewall_validate_post_apply() {
  hardhat_module_firewall_collect_audit
  hardhat_firewall_detect_ssh_context

  local has_failed=0
  local has_warning=0

  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Validacion posterior a apply: UFW no aparece como activo."
    else
      hardhat_log_error "Post-apply validation: UFW is not reported as active."
    fi
    has_failed=1
  fi

  if [[ "${HARDHAT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_warn "Validacion posterior a apply: no se pudo leer la politica por defecto de UFW."
    else
      hardhat_log_warn "Post-apply validation: could not read UFW default policy."
    fi
    has_warning=1
  elif ! grep -qiE '(deny|reject)[[:space:]]*\(incoming\)' <<<"${HARDHAT_UFW_DEFAULT_POLICY}"; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Validacion posterior a apply: la politica de entrada por defecto no es deny/reject."
    else
      hardhat_log_error "Post-apply validation: incoming default policy is not deny/reject."
    fi
    has_failed=1
  fi

  if [[ "${HARDHAT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_warn "Validacion posterior a apply: no se pudo verificar con confianza la politica de salida por defecto (allow)."
    else
      hardhat_log_warn "Post-apply validation: could not confidently verify default outgoing policy (allow)."
    fi
    has_warning=1
  elif ! grep -qiE 'allow[[:space:]]*\(outgoing\)' <<<"${HARDHAT_UFW_DEFAULT_POLICY}"; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "Validacion posterior a apply: la politica de salida por defecto no es allow."
    else
      hardhat_log_error "Post-apply validation: outgoing default policy is not allow."
    fi
    has_failed=1
  fi

  if [[ "${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_RULE}" -eq 1 ]]; then
    if [[ "${HARDHAT_FIREWALL_RULES_SOURCE}" == "unavailable" ]]; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_warn "Validacion posterior a apply: no se pudieron leer reglas UFW para verificar regla SSH esperada."
      else
        hardhat_log_warn "Post-apply validation: UFW rules could not be read to verify expected SSH allow rule."
      fi
      has_warning=1
    elif hardhat_firewall_has_allow_rule_for_port "${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT}"; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_success "Validacion posterior a apply: regla SSH allow presente para ${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT}/tcp."
      else
        hardhat_log_success "Post-apply validation: SSH allow rule present for ${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT}/tcp."
      fi
    else
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "Validacion posterior a apply: falta regla SSH allow esperada para ${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT}/tcp."
      else
        hardhat_log_error "Post-apply validation: expected SSH allow rule missing for ${HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT}/tcp."
      fi
      has_failed=1
    fi
  fi

  if [[ "${has_failed}" -eq 1 ]]; then
    HARDHAT_FIREWALL_APPLY_VALIDATION_RESULT="failed"
    if hardhat_firewall_is_spanish; then
      hardhat_log_error "firewall apply no cumple baseline esperada; revisa y corrige estado final."
    else
      hardhat_log_error "Firewall apply does not meet expected baseline; review and remediate final state."
    fi
    return 2
  fi

  if [[ "${has_warning}" -eq 1 ]]; then
    HARDHAT_FIREWALL_APPLY_VALIDATION_RESULT="warning"
    if hardhat_firewall_is_spanish; then
      hardhat_log_warn "firewall apply finalizo con advertencias de validacion; revisa el estado manualmente."
    else
      hardhat_log_warn "Firewall apply completed with validation warnings; review status manually."
    fi
    return 1
  fi

  HARDHAT_FIREWALL_APPLY_VALIDATION_RESULT="success"
  if hardhat_firewall_is_spanish; then
    hardhat_log_success "Linea base de firewall aplicada y validada."
  else
    hardhat_log_success "Firewall baseline applied and validated."
  fi
  return 0
}

hardhat_module_firewall_collect_audit() {
  hardhat_firewall_reset_state

  if ! command -v ufw >/dev/null 2>&1; then
    HARDHAT_FIREWALL_BACKEND_MISSING=1
    HARDHAT_FIREWALL_INSTALL_RECOMMENDED=1
    if hardhat_detect_arch_linux && command -v pacman >/dev/null 2>&1; then
      HARDHAT_FIREWALL_INSTALL_SUPPORTED=1
      HARDHAT_FIREWALL_INSTALL_METHOD="pacman"
    fi

    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "UFW no esta instalado en este sistema."
      hardhat_firewall_add_note "No hay una linea base de firewall soportada por el MVP activa."
      hardhat_firewall_add_note "La exposicion del sistema aumenta hasta aplicar una politica de linea base de firewall."
      hardhat_firewall_add_finding \
        "firewall.ufw.missing" \
        "high" \
        "Backend de firewall soportado ausente" \
        "UFW no esta instalado, por lo que HardHat no puede confirmar ni aplicar la linea base de firewall del MVP. Esto aumenta exposicion del sistema." \
        "Instala y configura UFW con 'hardhat firewall apply' (o instala UFW con pacman y luego ejecuta 'hardhat firewall apply')."
    else
      hardhat_firewall_add_note "UFW is not installed on this system."
      hardhat_firewall_add_note "No MVP-supported firewall baseline is currently active."
      hardhat_firewall_add_note "System exposure is increased until a baseline firewall policy is applied."
      hardhat_firewall_add_finding \
        "firewall.ufw.missing" \
        "high" \
        "Supported firewall backend missing" \
        "UFW is not installed, so HardHat cannot confirm or enforce the MVP firewall baseline. This increases system exposure." \
        "Install and configure UFW using 'hardhat firewall apply' (or install UFW with pacman first, then run 'hardhat firewall apply')."
    fi
    hardhat_firewall_compute_severity
    return 0
  fi

  HARDHAT_UFW_INSTALLED=1
  if hardhat_firewall_is_spanish; then
    hardhat_firewall_add_note "UFW esta instalado."
  else
    hardhat_firewall_add_note "UFW is installed."
  fi

  local status_output=""
  if ! status_output="$(hardhat_firewall_run_ufw_capture status)"; then
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "No se pudo leer el estado de UFW con los privilegios actuales; la auditoria continua con visibilidad parcial de firewall."
      hardhat_firewall_add_finding \
        "firewall.ufw.status_unavailable" \
        "low" \
        "Estado de UFW no disponible" \
        "HardHat no pudo recuperar la salida actual de estado de UFW." \
        "Ejecuta la auditoria con permisos que permitan leer estado de UFW."
    else
      hardhat_firewall_add_note "UFW status could not be read with current privileges; audit continues with partial firewall visibility."
      hardhat_firewall_add_finding \
        "firewall.ufw.status_unavailable" \
        "low" \
        "UFW status unavailable" \
        "HardHat could not retrieve current UFW status output." \
        "Run audit with permissions that allow reading UFW status."
    fi
    hardhat_firewall_compute_severity
    return 0
  fi

  if grep -qiE 'status:[[:space:]]*active' <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="yes"
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "UFW esta activo."
    else
      hardhat_firewall_add_note "UFW is active."
    fi
  elif grep -qiE 'status:[[:space:]]*inactive' <<<"${status_output}"; then
    HARDHAT_UFW_ACTIVE="no"
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "UFW esta instalado pero inactivo."
      hardhat_firewall_add_finding \
        "firewall.ufw.inactive" \
        "high" \
        "UFW inactivo" \
        "El firewall esta instalado pero no esta aplicando reglas de filtrado." \
        "Habilita UFW y aplica la linea base (deny incoming, allow outgoing)."
    else
      hardhat_firewall_add_note "UFW is installed but inactive."
      hardhat_firewall_add_finding \
        "firewall.ufw.inactive" \
        "high" \
        "UFW inactive" \
        "Firewall is installed but not enforcing any filtering rules." \
        "Enable UFW and apply baseline defaults (deny incoming, allow outgoing)."
    fi
  else
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "El estado de UFW no reporto claramente si esta activo o inactivo."
    else
      hardhat_firewall_add_note "UFW status did not report active or inactive clearly."
    fi
  fi

  local status_verbose_output=""
  if status_verbose_output="$(hardhat_firewall_run_ufw_capture status verbose)"; then
    HARDHAT_UFW_DEFAULT_POLICY="$(hardhat_firewall_extract_default_policy "${status_verbose_output}")"
    if [[ "${HARDHAT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
      if hardhat_firewall_is_spanish; then
        hardhat_firewall_add_note "No se pudo extraer la politica por defecto de UFW."
        hardhat_firewall_add_finding \
          "firewall.ufw.default_unknown" \
          "low" \
          "Politica por defecto de UFW desconocida" \
          "HardHat no pudo interpretar la politica por defecto desde la salida detallada de UFW." \
          "Inspecciona los valores por defecto de UFW manualmente con ufw status verbose."
      else
        hardhat_firewall_add_note "UFW default policy could not be extracted."
        hardhat_firewall_add_finding \
          "firewall.ufw.default_unknown" \
          "low" \
          "UFW default policy unknown" \
          "HardHat could not parse default policy from UFW verbose output." \
          "Inspect UFW defaults manually with ufw status verbose."
      fi
    else
      if hardhat_firewall_is_spanish; then
        hardhat_firewall_add_note "Politica por defecto de UFW: ${HARDHAT_UFW_DEFAULT_POLICY}."
      else
        hardhat_firewall_add_note "UFW default policy: ${HARDHAT_UFW_DEFAULT_POLICY}."
      fi
      if ! grep -qiE '(deny|reject)[[:space:]]*\(incoming\)' <<<"${HARDHAT_UFW_DEFAULT_POLICY}"; then
        if hardhat_firewall_is_spanish; then
          hardhat_firewall_add_finding \
            "firewall.ufw.default_incoming" \
            "medium" \
            "Politica de entrada por defecto debil" \
            "La politica de entrada por defecto de UFW no es deny/reject." \
            "Configura la politica de entrada por defecto de UFW en deny."
        else
          hardhat_firewall_add_finding \
            "firewall.ufw.default_incoming" \
            "medium" \
            "Weak default incoming policy" \
            "UFW default incoming policy is not deny/reject." \
            "Set UFW default incoming policy to deny."
        fi
      fi
    fi
  else
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "Salida detallada de UFW no disponible para verificar politica por defecto."
    else
      hardhat_firewall_add_note "UFW verbose output unavailable for default policy check."
    fi
  fi

  local rules_output=""
  if rules_output="$(hardhat_firewall_run_ufw_capture status numbered)"; then
    HARDHAT_FIREWALL_RULES_SOURCE="numbered"
    hardhat_firewall_extract_rules "${rules_output}"
  elif rules_output="$(hardhat_firewall_run_ufw_capture status)"; then
    HARDHAT_FIREWALL_RULES_SOURCE="status"
    hardhat_firewall_extract_rules "${rules_output}"
  else
    HARDHAT_FIREWALL_RULES_SOURCE="unavailable"
    if hardhat_firewall_is_spanish; then
      hardhat_firewall_add_note "Salida de reglas UFW no disponible."
    else
      hardhat_firewall_add_note "UFW rules output unavailable."
    fi
  fi

  hardhat_firewall_analyze_rules
  hardhat_firewall_compute_severity
}

hardhat_module_firewall_render_human() {
  local findings_count="${#HARDHAT_FIREWALL_FINDINGS[@]}"
  if hardhat_firewall_is_spanish; then
    local backend_missing_text="no"
    local installed_text="no"
    local active_text="${HARDHAT_UFW_ACTIVE}"
    local default_policy_text="${HARDHAT_UFW_DEFAULT_POLICY}"

    if [[ "${HARDHAT_FIREWALL_BACKEND_MISSING}" -eq 1 ]]; then
      backend_missing_text="si"
    fi

    if [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]]; then
      installed_text="si"
    fi

    if [[ "${active_text}" == "unknown" ]]; then
      active_text="desconocido"
    fi

    if [[ "${default_policy_text}" == "unknown" ]]; then
      default_policy_text="desconocida"
    fi

    printf 'Auditoria de Firewall HardHat\n'
    printf 'Backend esperado: UFW\n'
    printf 'Backend ausente: %s\n' "${backend_missing_text}"
    printf 'Instalado: %s\n' "${installed_text}"
    printf 'Activo: %s\n' "${active_text}"
    printf 'Politica por defecto: %s\n' "${default_policy_text}"
    printf 'Reglas detectadas: %s\n' "${#HARDHAT_UFW_RULES[@]}"
    printf 'Severidad general: %s\n' "${HARDHAT_FIREWALL_SEVERITY}"
    printf 'Hallazgos: %s\n\n' "${findings_count}"

    if [[ "${HARDHAT_FIREWALL_BACKEND_MISSING}" -eq 1 ]]; then
      printf 'Estado de riesgo: ALTO\n'
      printf 'UFW falta, por lo que este sistema no tiene una linea base de firewall del MVP activa.\n'
      printf 'Por que importa: la exposicion entrante puede ser mayor sin filtrado de linea base.\n'
      if [[ "${HARDHAT_FIREWALL_INSTALL_SUPPORTED}" -eq 1 ]]; then
        printf 'Accion: ejecuta hardhat firewall apply para instalar/configurar UFW con flujo guiado de linea base.\n\n'
      else
        printf 'Accion: instala UFW y luego ejecuta hardhat firewall apply para aplicar la linea base.\n\n'
      fi
    fi

    local note
    for note in "${HARDHAT_FIREWALL_NOTES[@]}"; do
      printf -- '- %s\n' "${note}"
    done

    if ((findings_count > 0)); then
      printf '\nHallazgos detallados:\n'
      local idx=1
      local item id severity title description recommendation
      for item in "${HARDHAT_FIREWALL_FINDINGS[@]}"; do
        IFS='|' read -r id severity title description recommendation <<<"${item}"
        printf '%s. [%s] %s (%s)\n' "${idx}" "${severity}" "${title}" "${id}"
        printf '   Descripcion: %s\n' "${description}"
        printf '   Recomendacion: %s\n' "${recommendation}"
        idx=$((idx + 1))
      done
    else
      printf '\nNo se detecto configuracion debil de firewall con los checks actuales.\n'
    fi

    if ((${#HARDHAT_FIREWALL_RECOMMENDATIONS[@]} > 0)); then
      printf '\nRecomendaciones:\n'
      local rec
      for rec in "${HARDHAT_FIREWALL_RECOMMENDATIONS[@]}"; do
        printf -- '- %s\n' "${rec}"
      done
    fi
    return 0
  fi

  printf 'HardHat Firewall Audit\n'
  printf 'Expected backend: UFW\n'
  printf 'Backend missing: %s\n' "$( [[ "${HARDHAT_FIREWALL_BACKEND_MISSING}" -eq 1 ]] && printf yes || printf no )"
  printf 'Installed: %s\n' "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf yes || printf no )"
  printf 'Active: %s\n' "${HARDHAT_UFW_ACTIVE}"
  printf 'Default policy: %s\n' "${HARDHAT_UFW_DEFAULT_POLICY}"
  printf 'Rules detected: %s\n' "${#HARDHAT_UFW_RULES[@]}"
  printf 'Overall severity: %s\n' "${HARDHAT_FIREWALL_SEVERITY}"
  printf 'Findings: %s\n\n' "${findings_count}"

  if [[ "${HARDHAT_FIREWALL_BACKEND_MISSING}" -eq 1 ]]; then
    printf 'Risk status: HIGH\n'
    printf 'UFW is missing, so this system has no MVP-supported firewall baseline active.\n'
    printf 'Why this matters: inbound exposure can be higher without baseline filtering.\n'
    if [[ "${HARDHAT_FIREWALL_INSTALL_SUPPORTED}" -eq 1 ]]; then
      printf 'Action: run hardhat firewall apply to install/configure UFW with the guided baseline flow.\n\n'
    else
      printf 'Action: install UFW and then run hardhat firewall apply to apply baseline defaults.\n\n'
    fi
  fi

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
  printf '"expected_backend":"ufw",'
  printf '"backend_present":%s,' "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf true || printf false )"
  printf '"backend_missing":%s,' "$( [[ "${HARDHAT_FIREWALL_BACKEND_MISSING}" -eq 1 ]] && printf true || printf false )"
  printf '"ufw_installed":%s,' "$( [[ "${HARDHAT_UFW_INSTALLED}" -eq 1 ]] && printf true || printf false )"
  printf '"active":'
  hardhat_json_nullable_string "${HARDHAT_UFW_ACTIVE}"
  printf ','
  printf '"default_policy":'
  hardhat_json_nullable_string "${HARDHAT_UFW_DEFAULT_POLICY}"
  printf ','
  printf '"install_recommended":%s,' "$( [[ "${HARDHAT_FIREWALL_INSTALL_RECOMMENDED}" -eq 1 ]] && printf true || printf false )"
  printf '"install_supported":%s,' "$( [[ "${HARDHAT_FIREWALL_INSTALL_SUPPORTED}" -eq 1 ]] && printf true || printf false )"
  printf '"install_method":'
  hardhat_json_nullable_string "${HARDHAT_FIREWALL_INSTALL_METHOD}"
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
  local requires_ufw_install=0
  local preconfirmed_apply=0
  # Default policy assumes pre-existing UFW and requires existing backup files.
  # It switches to 0 only when UFW was missing and installed in this run.
  local backup_require_existing_files=1

  hardhat_firewall_apply_reset_state
  HARDHAT_FIREWALL_APPLY_DRY_RUN="${HARDHAT_DRY_RUN:-0}"

  if ! hardhat_firewall_validate_environment; then
    hardhat_firewall_apply_add_note "Environment validation failed."
    hardhat_module_firewall_collect_audit || true
    HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
    hardhat_firewall_apply_finish "failed" "environment validation failed" 1
    return $?
  fi

  hardhat_module_firewall_collect_audit
  HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_BEFORE="${HARDHAT_UFW_INSTALLED}"

  if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
    requires_ufw_install=1
    HARDHAT_FIREWALL_APPLY_UFW_INSTALL_ATTEMPTED=1
    hardhat_firewall_apply_add_note "UFW was not installed before apply."
    hardhat_firewall_report_missing_backend
  fi

  hardhat_firewall_detect_ssh_context
  if [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]]; then
    HARDHAT_FIREWALL_APPLY_EXPECT_SSH_RULE=1
    HARDHAT_FIREWALL_APPLY_EXPECT_SSH_PORT="${HARDHAT_FIREWALL_SSH_PORT}"
  fi
  hardhat_firewall_build_apply_plan
  if [[ "${HARDHAT_OUTPUT_JSON:-0}" -ne 1 ]]; then
    hardhat_firewall_render_apply_plan
  fi

  if [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]]; then
    if hardhat_firewall_is_spanish; then
      hardhat_log_info "Modo dry-run habilitado: no se realizaron cambios."
    else
      hardhat_log_info "Dry-run mode enabled: no changes were made."
    fi
    if [[ "${requires_ufw_install}" -eq 1 ]]; then
      hardhat_firewall_write_log "dry-run missing_ufw_plan_reviewed"
    else
      hardhat_firewall_write_log "dry-run plan_reviewed"
    fi
    HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
    hardhat_firewall_apply_add_note "Dry-run completed; no changes were applied."
    hardhat_firewall_apply_finish "dry-run" "dry-run completed" 0
    return $?
  fi

  if [[ "${requires_ufw_install}" -eq 1 ]]; then
    if hardhat_firewall_is_spanish; then
      if ! hardhat_confirm_global "UFW no esta instalado. Instalar UFW con pacman y aplicar ahora la linea base de firewall?"; then
        hardhat_firewall_write_log "aborted missing_ufw_user_cancelled"
        HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
        hardhat_firewall_apply_add_note "User cancelled before UFW installation."
        hardhat_firewall_apply_finish "aborted" "user cancelled before install" 1
        return $?
      fi
    elif ! hardhat_confirm_global "UFW is missing. Install UFW with pacman and apply the firewall baseline now?"; then
      hardhat_firewall_write_log "aborted missing_ufw_user_cancelled"
      HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
      hardhat_firewall_apply_add_note "User cancelled before UFW installation."
      hardhat_firewall_apply_finish "aborted" "user cancelled before install" 1
      return $?
    fi
    preconfirmed_apply=1

    if ! hardhat_firewall_install_ufw; then
      hardhat_firewall_write_log "failed ufw_install"
      hardhat_module_firewall_collect_audit || true
      HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
      hardhat_firewall_apply_add_note "UFW installation failed."
      hardhat_firewall_apply_finish "failed" "ufw installation failed" 1
      return $?
    fi

    HARDHAT_FIREWALL_APPLY_UFW_INSTALL_SUCCEEDED=1

    hardhat_module_firewall_collect_audit
    if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "UFW aun no se detecta despues del intento de instalacion; abortando apply."
      else
        hardhat_log_error "UFW still not detected after installation attempt; aborting apply."
      fi
      hardhat_firewall_write_log "failed ufw_not_detected_after_install"
      HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
      hardhat_firewall_apply_add_note "UFW still not detected after installation attempt."
      hardhat_firewall_apply_finish "failed" "ufw not detected after install" 1
      return $?
    fi

    if hardhat_firewall_is_spanish; then
      hardhat_log_info "Instalacion de UFW completada. Continuando con configuracion de linea base."
    else
      hardhat_log_info "UFW installation completed. Continuing with baseline configuration."
    fi
    hardhat_firewall_detect_ssh_context
    backup_require_existing_files=0
  fi

  HARDHAT_FIREWALL_APPLY_BACKUPS_REQUIRED="${backup_require_existing_files}"

  if ! hardhat_firewall_create_backups_or_fail "${backup_require_existing_files}"; then
    hardhat_firewall_write_log "aborted backup_failed"
    hardhat_module_firewall_collect_audit || true
    HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
    hardhat_firewall_apply_add_note "Backup stage failed."
    hardhat_firewall_apply_finish "failed" "backup stage failed" 1
    return $?
  fi

  if [[ "${preconfirmed_apply}" -ne 1 ]]; then
    if hardhat_firewall_is_spanish; then
      if ! hardhat_confirm_global "Continuar con firewall apply de linea base?"; then
        hardhat_firewall_write_log "aborted user_cancelled"
        HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
        hardhat_firewall_apply_add_note "User cancelled before apply actions."
        hardhat_firewall_apply_finish "aborted" "user cancelled before apply" 1
        return $?
      fi
    elif ! hardhat_confirm_global "Proceed with firewall baseline apply?"; then
      hardhat_firewall_write_log "aborted user_cancelled"
      HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
      hardhat_firewall_apply_add_note "User cancelled before apply actions."
      hardhat_firewall_apply_finish "aborted" "user cancelled before apply" 1
      return $?
    fi
  fi

  if hardhat_firewall_is_spanish; then
    hardhat_log_warn "No hay rollback automatico en esta fase."
  else
    hardhat_log_warn "Automatic rollback is not available in this phase."
  fi

  HARDHAT_FIREWALL_APPLY_ATTEMPTED=1
  if ! hardhat_firewall_apply_actions; then
    hardhat_firewall_write_log "failed apply_actions"
    hardhat_module_firewall_collect_audit || true
    HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
    hardhat_firewall_apply_add_note "Apply actions failed."
    hardhat_firewall_apply_finish "failed" "apply actions failed" 1
    return $?
  fi

  HARDHAT_FIREWALL_APPLY_SUCCEEDED=1

  local validate_rc=0
  if hardhat_firewall_validate_post_apply; then
    HARDHAT_FIREWALL_APPLY_VALIDATION_SUCCEEDED=1
    hardhat_firewall_write_log "success validated"
    if hardhat_firewall_is_spanish; then
      hardhat_log_info "Estado final: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
    else
      hardhat_log_info "Final state: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
    fi
    HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
    hardhat_firewall_apply_add_note "Apply and validation completed successfully."
    hardhat_firewall_apply_finish "success" "firewall apply completed successfully" 0
    return $?
  fi
  validate_rc=$?

  if [[ "${validate_rc}" -eq 2 ]]; then
    hardhat_firewall_write_log "failed validation_failed"
  else
    hardhat_firewall_write_log "warning validation_failed"
  fi
  if hardhat_firewall_is_spanish; then
    hardhat_log_warn "Estado final: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
  else
    hardhat_log_warn "Final state: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
  fi
  HARDHAT_FIREWALL_APPLY_UFW_INSTALLED_AFTER="${HARDHAT_UFW_INSTALLED}"
  if [[ "${validate_rc}" -eq 2 ]]; then
    hardhat_firewall_apply_add_note "Apply completed but post-apply validation found missing baseline conditions."
    hardhat_firewall_apply_finish "failed" "firewall apply completed but baseline validation failed" 1
    return $?
  fi

  hardhat_firewall_apply_add_note "Apply completed but post-apply validation reported warnings."
  hardhat_firewall_apply_finish "warning" "firewall apply completed with validation warnings" 1
  return $?
}

hardhat_module_firewall_run() {
  local subcommand="${1:-audit}"
  local validate_status=0

  case "${subcommand}" in
    -h|--help|help)
      hardhat_module_firewall_usage
      ;;
    audit)
      hardhat_module_firewall_validate_subcommand_args audit "${@:2}" || validate_status=$?
      if [[ "${validate_status}" -eq 2 ]]; then
        return 0
      fi
      if [[ "${validate_status}" -ne 0 ]]; then
        hardhat_module_firewall_audit_usage
        return 1
      fi
      hardhat_module_firewall_audit
      ;;
    apply)
      hardhat_module_firewall_validate_subcommand_args apply "${@:2}" || validate_status=$?
      if [[ "${validate_status}" -eq 2 ]]; then
        return 0
      fi
      if [[ "${validate_status}" -ne 0 ]]; then
        hardhat_module_firewall_apply_usage
        return 1
      fi
      hardhat_module_firewall_apply
      ;;
    *)
      if hardhat_firewall_is_spanish; then
        hardhat_log_error "Subcomando de firewall desconocido: ${subcommand}"
        hardhat_log_info "Usa 'hardhat firewall help' para ver subcomandos disponibles."
      else
        hardhat_log_error "Unknown firewall subcommand: ${subcommand}"
        hardhat_log_info "Use 'hardhat firewall help' to see available subcommands."
      fi
      hardhat_module_firewall_usage
      return 1
      ;;
  esac
}