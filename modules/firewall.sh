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
HARDHAT_FIREWALL_LOG_FILE="/var/log/hardhat.log"

hardhat_module_firewall_usage() {
  if hardhat_firewall_is_spanish; then
    cat <<'EOF'
Uso:
  hardhat firewall audit [--json]
  hardhat firewall apply [--dry-run] [--yes]

Nota:
  Si UFW no esta instalado, apply puede guiar su instalacion antes de aplicar la linea base.
EOF
    return 0
  fi

  cat <<'EOF'
Usage:
  hardhat firewall audit [--json]
  hardhat firewall apply [--dry-run] [--yes]

Note:
  If UFW is missing, apply can guide installation before baseline configuration.
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
  HARDHAT_FIREWALL_PLAN=()
  HARDHAT_FIREWALL_SSH_ACTIVE=0
  HARDHAT_FIREWALL_SSH_PORT="unknown"
  HARDHAT_FIREWALL_SSH_RULE_NEEDED=0
  HARDHAT_FIREWALL_BACKEND_MISSING=0
  HARDHAT_FIREWALL_INSTALL_RECOMMENDED=0
  HARDHAT_FIREWALL_INSTALL_SUPPORTED=0
  HARDHAT_FIREWALL_INSTALL_METHOD="unknown"
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
    hardhat_firewall_add_note "sshd is active. Detected SSH port: ${HARDHAT_FIREWALL_SSH_PORT}."

    local rules_text
    rules_text="$(printf '%s\n' "${HARDHAT_UFW_RULES[@]}")"
    if grep -qiE "${HARDHAT_FIREWALL_SSH_PORT}(/tcp)?[[:space:]].*(ALLOW)" <<<"${rules_text}"; then
      HARDHAT_FIREWALL_SSH_RULE_NEEDED=0
      hardhat_firewall_add_note "An allow rule for SSH port ${HARDHAT_FIREWALL_SSH_PORT} appears to exist."
    else
      HARDHAT_FIREWALL_SSH_RULE_NEEDED=1
      hardhat_firewall_add_note "No explicit allow rule found for SSH port ${HARDHAT_FIREWALL_SSH_PORT}."
      hardhat_firewall_add_recommendation "Allow SSH port ${HARDHAT_FIREWALL_SSH_PORT}/tcp before enabling strict defaults."
    fi
  else
    hardhat_firewall_add_note "sshd is not active."
  fi
}

hardhat_firewall_validate_environment() {
  if ! hardhat_detect_arch_linux; then
    hardhat_log_error "HardHat firewall apply currently supports only Arch Linux."
    return 1
  fi

  if ! hardhat_require_elevated_or_sudo; then
    return 1
  fi

  return 0
}

hardhat_firewall_report_missing_backend() {
  hardhat_log_warn "UFW is not installed. No supported firewall backend is configured for this MVP."
  hardhat_log_warn "This system currently has no HardHat firewall baseline and may be exposed to inbound traffic."
  hardhat_log_info "HardHat can install UFW and apply a safe baseline now."
}

hardhat_firewall_install_ufw() {
  if command -v ufw >/dev/null 2>&1; then
    hardhat_log_info "UFW is already installed."
    return 0
  fi

  if ! command -v pacman >/dev/null 2>&1; then
    hardhat_log_error "pacman is not available; cannot install UFW automatically."
    return 1
  fi

  local -a pacman_args=(-S --needed ufw)
  if [[ "${HARDHAT_ASSUME_YES:-0}" -eq 1 ]]; then
    pacman_args=(-S --needed --noconfirm ufw)
  fi

  hardhat_log_info "Installing UFW with pacman..."
  if ! hardhat_sudo_run pacman "${pacman_args[@]}"; then
    hardhat_log_error "Failed to install UFW via pacman."
    return 1
  fi

  if ! command -v ufw >/dev/null 2>&1; then
    hardhat_log_error "UFW installation command completed but ufw is still unavailable in PATH."
    return 1
  fi

  hardhat_log_success "UFW installed successfully."
  return 0
}

hardhat_firewall_build_apply_plan() {
  HARDHAT_FIREWALL_PLAN=()

  if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
    HARDHAT_FIREWALL_PLAN+=("Install UFW package with pacman.")
    HARDHAT_FIREWALL_PLAN+=("Collect current UFW status after installation.")
  fi

  HARDHAT_FIREWALL_PLAN+=("Create backups of UFW configuration files before applying policy changes.")
  HARDHAT_FIREWALL_PLAN+=("Set UFW default incoming policy to deny.")
  HARDHAT_FIREWALL_PLAN+=("Set UFW default outgoing policy to allow.")

  if [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]]; then
    HARDHAT_FIREWALL_PLAN+=("Add UFW allow rule for SSH on port ${HARDHAT_FIREWALL_SSH_PORT}/tcp.")
  fi

  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    HARDHAT_FIREWALL_PLAN+=("Enable UFW to enforce firewall rules.")
  else
    HARDHAT_FIREWALL_PLAN+=("UFW already active; refresh baseline defaults without disabling firewall.")
  fi
}

hardhat_firewall_render_apply_plan() {
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

  for source_file in "${candidates[@]}"; do
    if [[ ! -f "${source_file}" ]]; then
      continue
    fi
    existing_count=$((existing_count + 1))

    if ! hardhat_backup_file "${source_file}" "${backup_dir}"; then
      hardhat_log_error "Backup failed for ${source_file}; aborting apply."
      return 1
    fi
    backup_count=$((backup_count + 1))
  done

  if ((existing_count == 0)); then
    if [[ "${require_existing_files}" -eq 1 ]]; then
      hardhat_log_error "UFW appears pre-existing but no configuration file was found for backup; refusing to apply changes."
      return 1
    fi

    hardhat_log_warn "No UFW configuration files found to back up after installation. Continuing with initial baseline apply."
    return 0
  fi

  hardhat_log_success "Backup stage completed (${backup_count} file(s))."
  return 0
}

hardhat_firewall_apply_actions() {
  if ! hardhat_sudo_run ufw --force default deny incoming; then
    hardhat_log_error "Failed to set UFW default incoming policy."
    return 1
  fi

  if ! hardhat_sudo_run ufw --force default allow outgoing; then
    hardhat_log_error "Failed to set UFW default outgoing policy."
    return 1
  fi

  if [[ "${HARDHAT_FIREWALL_SSH_ACTIVE}" -eq 1 ]] && [[ "${HARDHAT_FIREWALL_SSH_RULE_NEEDED}" -eq 1 ]]; then
    if ! hardhat_sudo_run ufw allow "${HARDHAT_FIREWALL_SSH_PORT}/tcp"; then
      hardhat_log_error "Failed to add SSH allow rule for port ${HARDHAT_FIREWALL_SSH_PORT}/tcp."
      return 1
    fi
  fi

  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    if ! hardhat_sudo_run ufw --force enable; then
      hardhat_log_error "Failed to enable UFW."
      return 1
    fi
  fi

  return 0
}

hardhat_firewall_validate_post_apply() {
  hardhat_module_firewall_collect_audit

  local ok=1
  if [[ "${HARDHAT_UFW_ACTIVE}" != "yes" ]]; then
    hardhat_log_warn "Post-apply validation: UFW is not reported as active."
    ok=0
  fi

  if [[ "${HARDHAT_UFW_DEFAULT_POLICY}" == "unknown" ]]; then
    hardhat_log_warn "Post-apply validation: could not read UFW default policy."
    ok=0
  elif ! grep -qiE '(deny|reject)[[:space:]]*\(incoming\)' <<<"${HARDHAT_UFW_DEFAULT_POLICY}"; then
    hardhat_log_warn "Post-apply validation: incoming default policy is not deny/reject."
    ok=0
  fi

  if [[ "${ok}" -eq 1 ]]; then
    hardhat_log_success "Firewall baseline applied and validated."
    return 0
  fi

  hardhat_log_warn "Firewall apply completed with validation warnings; review status manually."
  return 1
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
    hardhat_firewall_extract_rules "${rules_output}"
  elif rules_output="$(hardhat_firewall_run_ufw_capture status)"; then
    hardhat_firewall_extract_rules "${rules_output}"
  else
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

  if ! hardhat_firewall_validate_environment; then
    return 1
  fi

  hardhat_module_firewall_collect_audit

  if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
    requires_ufw_install=1
    hardhat_firewall_report_missing_backend
  fi

  hardhat_firewall_detect_ssh_context
  hardhat_firewall_build_apply_plan
  hardhat_firewall_render_apply_plan

  if [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]]; then
    hardhat_log_info "Dry-run mode enabled: no changes were made."
    if [[ "${requires_ufw_install}" -eq 1 ]]; then
      hardhat_firewall_write_log "dry-run missing_ufw_plan_reviewed"
    else
      hardhat_firewall_write_log "dry-run plan_reviewed"
    fi
    return 0
  fi

  if [[ "${requires_ufw_install}" -eq 1 ]]; then
    if ! hardhat_confirm_global "UFW is missing. Install UFW with pacman and apply the firewall baseline now?"; then
      hardhat_firewall_write_log "aborted missing_ufw_user_cancelled"
      return 1
    fi
    preconfirmed_apply=1

    if ! hardhat_firewall_install_ufw; then
      hardhat_firewall_write_log "failed ufw_install"
      return 1
    fi

    hardhat_module_firewall_collect_audit
    if [[ "${HARDHAT_UFW_INSTALLED}" -ne 1 ]]; then
      hardhat_log_error "UFW still not detected after installation attempt; aborting apply."
      hardhat_firewall_write_log "failed ufw_not_detected_after_install"
      return 1
    fi

    hardhat_log_info "UFW installation completed. Continuing with baseline configuration."
    hardhat_firewall_detect_ssh_context
    backup_require_existing_files=0
  fi

  if ! hardhat_firewall_create_backups_or_fail "${backup_require_existing_files}"; then
    hardhat_firewall_write_log "aborted backup_failed"
    return 1
  fi

  if [[ "${preconfirmed_apply}" -ne 1 ]]; then
    if ! hardhat_confirm_global "Proceed with firewall baseline apply?"; then
      hardhat_firewall_write_log "aborted user_cancelled"
      return 1
    fi
  fi

  hardhat_log_warn "Automatic rollback is not available in this phase."

  if ! hardhat_firewall_apply_actions; then
    hardhat_firewall_write_log "failed apply_actions"
    return 1
  fi

  if hardhat_firewall_validate_post_apply; then
    hardhat_firewall_write_log "success validated"
    hardhat_log_info "Final state: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
    return 0
  fi

  hardhat_firewall_write_log "warning validation_failed"
  hardhat_log_warn "Final state: active=${HARDHAT_UFW_ACTIVE}, default_policy=${HARDHAT_UFW_DEFAULT_POLICY}."
  return 1
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