#!/usr/bin/env bash

HARDHAT_DOCTOR_CHECKS=()
HARDHAT_DOCTOR_NOTES=()
HARDHAT_DOCTOR_RECOMMENDATIONS=()
HARDHAT_DOCTOR_SUMMARY=""
HARDHAT_DOCTOR_STATUS="unknown"
HARDHAT_DOCTOR_STATUS_MESSAGE=""
HARDHAT_DOCTOR_EXIT_CODE=0
HARDHAT_DOCTOR_TOTAL_CHECKS=0
HARDHAT_DOCTOR_PASS_COUNT=0
HARDHAT_DOCTOR_WARN_COUNT=0
HARDHAT_DOCTOR_FAIL_COUNT=0
HARDHAT_DOCTOR_INFO_COUNT=0
HARDHAT_DOCTOR_READY=0

hardhat_doctor_is_spanish() {
  [[ "${HARDHAT_LANG:-en}" == "es" ]]
}

hardhat_module_doctor_usage() {
  if hardhat_doctor_is_spanish; then
    cat <<'EOF'
HardHat doctor - Diagnostico general seguro

Uso:
  hardhat doctor [opciones]

Descripcion:
  Ejecuta checks de solo lectura para validar si el entorno esta listo para usar HardHat
  de forma segura y predecible en enfoque Arch-first.

Opciones:
  -h, --help          Muestra esta ayuda
  --json              Emite salida JSON en stdout

Ejemplos:
  hardhat doctor
  hardhat doctor --json
EOF
    return 0
  fi

  cat <<'EOF'
HardHat doctor - Safe general diagnostics

Usage:
  hardhat doctor [options]

Description:
  Runs read-only checks to validate whether the environment is ready to use HardHat
  safely and predictably with an Arch-first focus.

Options:
  -h, --help          Show this help
  --json              Emit JSON output on stdout

Examples:
  hardhat doctor
  hardhat doctor --json
EOF
}

hardhat_doctor_add_note() {
  HARDHAT_DOCTOR_NOTES+=("$*")
}

hardhat_doctor_add_check() {
  local check_id="$1"
  local result="$2"
  local title="$3"
  local details="$4"
  local recommendation="$5"

  HARDHAT_DOCTOR_CHECKS+=("${check_id}|${result}|${title}|${details}|${recommendation}")
}

hardhat_doctor_detect_id_like() {
  if [[ -f /etc/os-release ]]; then
    local id_like
    id_like="$(grep -E '^ID_LIKE=' /etc/os-release 2>/dev/null | head -n 1 | cut -d= -f2- | tr -d '"')"
    printf '%s' "${id_like}"
    return 0
  fi

  printf 'unknown'
  return 1
}

hardhat_doctor_has_arch_like() {
  local distro_id
  local id_like

  distro_id="$(hardhat_detect_distro_id || printf 'unknown')"
  id_like="$(hardhat_doctor_detect_id_like || printf 'unknown')"

  if [[ "${distro_id}" == "arch" ]]; then
    return 0
  fi

  [[ "${id_like}" == *arch* ]]
}

hardhat_doctor_collect_platform_check() {
  local distro_id
  local id_like

  distro_id="$(hardhat_detect_distro_id || printf 'unknown')"
  id_like="$(hardhat_doctor_detect_id_like || printf 'unknown')"

  if hardhat_doctor_has_arch_like; then
    hardhat_doctor_add_check \
      "platform.arch" \
      "pass" \
      "Arch-first platform support" \
      "Detected distro=${distro_id}, id_like=${id_like}." \
      ""
    return 0
  fi

  hardhat_doctor_add_check \
    "platform.arch" \
    "fail" \
    "Arch-first platform support" \
    "Detected distro=${distro_id}, id_like=${id_like}." \
    "Run HardHat on Arch Linux (or an Arch-compatible environment) for supported behavior."
  hardhat_doctor_add_note "Environment is outside current official support scope (Arch-first)."
}

hardhat_doctor_collect_tools_checks() {
  local distro_arch_like=0
  hardhat_doctor_has_arch_like && distro_arch_like=1

  if command -v bash >/dev/null 2>&1; then
    hardhat_doctor_add_check \
      "tool.bash" \
      "pass" \
      "bash available" \
      "bash command is available in PATH." \
      ""
  else
    hardhat_doctor_add_check \
      "tool.bash" \
      "fail" \
      "bash available" \
      "bash command is not available in PATH." \
      "Install bash and ensure it is available in PATH."
  fi

  if command -v pacman >/dev/null 2>&1; then
    hardhat_doctor_add_check \
      "tool.pacman" \
      "pass" \
      "pacman available" \
      "pacman command is available in PATH." \
      ""
  else
    if [[ "${distro_arch_like}" -eq 1 ]]; then
      hardhat_doctor_add_check \
        "tool.pacman" \
        "fail" \
        "pacman available" \
        "pacman command is missing in an Arch-like environment." \
        "Verify pacman installation and PATH before using HardHat firewall/install workflows."
    else
      hardhat_doctor_add_check \
        "tool.pacman" \
        "warn" \
        "pacman available" \
        "pacman command is not available in PATH." \
        "Use Arch Linux for officially supported package/install workflows."
    fi
  fi

  if command -v sudo >/dev/null 2>&1; then
    hardhat_doctor_add_check \
      "tool.sudo" \
      "pass" \
      "sudo available" \
      "sudo command is available in PATH." \
      ""
  else
    if [[ "${EUID}" -eq 0 ]]; then
      hardhat_doctor_add_check \
        "tool.sudo" \
        "info" \
        "sudo available" \
        "sudo command is missing, but current session is root." \
        ""
    else
      hardhat_doctor_add_check \
        "tool.sudo" \
        "warn" \
        "sudo available" \
        "sudo command is not available in PATH for a non-root session." \
        "Install sudo or run privileged actions as root when required."
    fi
  fi

  if command -v ufw >/dev/null 2>&1; then
    hardhat_doctor_add_check \
      "tool.ufw" \
      "pass" \
      "ufw available" \
      "ufw command is available in PATH." \
      ""
  else
    hardhat_doctor_add_check \
      "tool.ufw" \
      "warn" \
      "ufw available" \
      "ufw command is not available in PATH." \
      "Use 'hardhat firewall apply' to guide UFW installation and baseline setup on Arch."
  fi
}

hardhat_doctor_collect_runtime_checks() {
  local runtime_dir="/opt/hardhat"
  local bin_usr_local="/usr/local/bin/hardhat"
  local bin_usr="/usr/bin/hardhat"
  local global_cfg="/etc/hardhat/config"
  local user_cfg="${HOME}/.config/hardhat/config"
  local command_present=0
  local command_integrity="pass"
  local command_details=""

  if [[ -d "${runtime_dir}" ]]; then
    hardhat_doctor_add_check \
      "runtime.path" \
      "pass" \
      "runtime directory" \
      "Runtime directory exists at ${runtime_dir}." \
      ""
  else
    hardhat_doctor_add_check \
      "runtime.path" \
      "info" \
      "runtime directory" \
      "Runtime directory not found at ${runtime_dir}." \
      "If installed manually, run install.sh. If using package flow, install the package with pacman."
  fi

  if [[ -e "${bin_usr_local}" || -e "${bin_usr}" ]]; then
    command_present=1
  fi

  if [[ "${command_present}" -eq 1 ]]; then
    hardhat_doctor_add_check \
      "runtime.command_path" \
      "pass" \
      "command path presence" \
      "Found command path at /usr/local/bin/hardhat and/or /usr/bin/hardhat." \
      ""
  else
    hardhat_doctor_add_check \
      "runtime.command_path" \
      "info" \
      "command path presence" \
      "No system command path found in /usr/local/bin/hardhat or /usr/bin/hardhat." \
      "Install HardHat (manual install.sh or Arch package) if system-wide command is expected."
  fi

  local path target
  for path in "${bin_usr_local}" "${bin_usr}"; do
    [[ -e "${path}" ]] || continue

    if [[ -L "${path}" ]]; then
      target="$(readlink -f "${path}" 2>/dev/null || true)"
      if [[ -n "${target}" ]] && [[ -x "${target}" ]]; then
        command_details+="${path}->${target}; "
      else
        command_integrity="warn"
        command_details+="${path} points to missing/non-executable target; "
      fi
      continue
    fi

    if [[ -x "${path}" ]]; then
      command_details+="${path} is executable file; "
    else
      command_integrity="warn"
      command_details+="${path} exists but is not executable; "
    fi
  done

  if [[ -z "${command_details}" ]]; then
    command_details="No command path to validate."
  fi

  if [[ "${command_integrity}" == "warn" ]]; then
    hardhat_doctor_add_check \
      "runtime.command_integrity" \
      "warn" \
      "command path integrity" \
      "${command_details}" \
      "Repair installation (reinstall package or rerun install.sh) if command path is broken."
  else
    hardhat_doctor_add_check \
      "runtime.command_integrity" \
      "pass" \
      "command path integrity" \
      "${command_details}" \
      ""
  fi

  if [[ -f "${global_cfg}" || -f "${user_cfg}" ]]; then
    hardhat_doctor_add_check \
      "runtime.config" \
      "pass" \
      "configuration presence" \
      "Detected config file in /etc/hardhat/config and/or ~/.config/hardhat/config." \
      ""
  else
    hardhat_doctor_add_check \
      "runtime.config" \
      "info" \
      "configuration presence" \
      "No global/user HardHat config file found yet." \
      "Run 'hardhat language set <en|es>' to initialize user configuration when needed."
  fi
}

hardhat_doctor_collect_context_checks() {
  if [[ -t 0 && -t 1 ]]; then
    hardhat_doctor_add_check \
      "context.tty" \
      "pass" \
      "interactive TTY context" \
      "stdin/stdout are interactive TTY." \
      ""
  else
    hardhat_doctor_add_check \
      "context.tty" \
      "info" \
      "interactive TTY context" \
      "Non-interactive context detected (stdin/stdout not both TTY)." \
      "Use an interactive terminal for 'hardhat menu' and confirmation flows."
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    hardhat_doctor_add_check \
      "context.privileges" \
      "pass" \
      "privilege context" \
      "Current session runs as root." \
      ""
  elif command -v sudo >/dev/null 2>&1; then
    hardhat_doctor_add_check \
      "context.privileges" \
      "pass" \
      "privilege context" \
      "Non-root session with sudo available." \
      ""
  else
    hardhat_doctor_add_check \
      "context.privileges" \
      "warn" \
      "privilege context" \
      "Non-root session without sudo available." \
      "Some privileged actions (install/apply/uninstall paths) may fail in this environment."
  fi
}

hardhat_doctor_collect_recommendations() {
  HARDHAT_DOCTOR_RECOMMENDATIONS=()
  local -A seen=()
  local item result recommendation

  for item in "${HARDHAT_DOCTOR_CHECKS[@]}"; do
    IFS='|' read -r _ result _ _ recommendation <<<"${item}"
    [[ -n "${recommendation}" ]] || continue

    case "${result}" in
      warn|fail)
        if [[ -z "${seen["${recommendation}"]+x}" ]]; then
          HARDHAT_DOCTOR_RECOMMENDATIONS+=("${recommendation}")
          seen["${recommendation}"]=1
        fi
        ;;
      *)
        ;;
    esac
  done
}

hardhat_doctor_calculate_summary() {
  HARDHAT_DOCTOR_TOTAL_CHECKS=0
  HARDHAT_DOCTOR_PASS_COUNT=0
  HARDHAT_DOCTOR_WARN_COUNT=0
  HARDHAT_DOCTOR_FAIL_COUNT=0
  HARDHAT_DOCTOR_INFO_COUNT=0

  local item result
  for item in "${HARDHAT_DOCTOR_CHECKS[@]}"; do
    IFS='|' read -r _ result _ _ _ <<<"${item}"
    HARDHAT_DOCTOR_TOTAL_CHECKS=$((HARDHAT_DOCTOR_TOTAL_CHECKS + 1))

    case "${result}" in
      pass)
        HARDHAT_DOCTOR_PASS_COUNT=$((HARDHAT_DOCTOR_PASS_COUNT + 1))
        ;;
      warn)
        HARDHAT_DOCTOR_WARN_COUNT=$((HARDHAT_DOCTOR_WARN_COUNT + 1))
        ;;
      fail)
        HARDHAT_DOCTOR_FAIL_COUNT=$((HARDHAT_DOCTOR_FAIL_COUNT + 1))
        ;;
      info)
        HARDHAT_DOCTOR_INFO_COUNT=$((HARDHAT_DOCTOR_INFO_COUNT + 1))
        ;;
      *)
        HARDHAT_DOCTOR_INFO_COUNT=$((HARDHAT_DOCTOR_INFO_COUNT + 1))
        ;;
    esac
  done

  HARDHAT_DOCTOR_READY=1
  if [[ "${HARDHAT_DOCTOR_FAIL_COUNT}" -gt 0 ]]; then
    HARDHAT_DOCTOR_READY=0
  fi

  HARDHAT_DOCTOR_SUMMARY="doctor checks completed"

  if [[ "${HARDHAT_DOCTOR_FAIL_COUNT}" -gt 0 ]]; then
    HARDHAT_DOCTOR_STATUS="warning"
    HARDHAT_DOCTOR_STATUS_MESSAGE="doctor completed with blocking issues"
    HARDHAT_DOCTOR_EXIT_CODE="${HARDHAT_EXIT_WARNING}"
    return 0
  fi

  if [[ "${HARDHAT_DOCTOR_WARN_COUNT}" -gt 0 ]]; then
    HARDHAT_DOCTOR_STATUS="warning"
    HARDHAT_DOCTOR_STATUS_MESSAGE="doctor completed with warnings"
    HARDHAT_DOCTOR_EXIT_CODE="${HARDHAT_EXIT_WARNING}"
    return 0
  fi

  HARDHAT_DOCTOR_STATUS="success"
  HARDHAT_DOCTOR_STATUS_MESSAGE="doctor completed"
  HARDHAT_DOCTOR_EXIT_CODE="${HARDHAT_EXIT_SUCCESS}"
}

hardhat_doctor_render_human() {
  printf 'HardHat Doctor Report\n'
  printf 'Summary: %s\n' "${HARDHAT_DOCTOR_SUMMARY}"
  printf 'Result: %s\n' "${HARDHAT_DOCTOR_STATUS}"
  printf 'Ready for Arch-first flow: %s\n' "$( [[ "${HARDHAT_DOCTOR_READY}" -eq 1 ]] && printf yes || printf no )"
  printf 'Checks: total=%s pass=%s warn=%s fail=%s info=%s\n\n' \
    "${HARDHAT_DOCTOR_TOTAL_CHECKS}" \
    "${HARDHAT_DOCTOR_PASS_COUNT}" \
    "${HARDHAT_DOCTOR_WARN_COUNT}" \
    "${HARDHAT_DOCTOR_FAIL_COUNT}" \
    "${HARDHAT_DOCTOR_INFO_COUNT}"

  printf 'Checks:\n'
  local item check_id result title details
  for item in "${HARDHAT_DOCTOR_CHECKS[@]}"; do
    IFS='|' read -r check_id result title details _ <<<"${item}"
    printf '  - [%s] %s (%s): %s\n' "${result}" "${title}" "${check_id}" "${details}"
  done

  if ((${#HARDHAT_DOCTOR_NOTES[@]} > 0)); then
    printf '\nNotes:\n'
    local note
    for note in "${HARDHAT_DOCTOR_NOTES[@]}"; do
      printf '  - %s\n' "${note}"
    done
  fi

  if ((${#HARDHAT_DOCTOR_RECOMMENDATIONS[@]} > 0)); then
    printf '\nRecommendations:\n'
    local rec
    for rec in "${HARDHAT_DOCTOR_RECOMMENDATIONS[@]}"; do
      printf '  - %s\n' "${rec}"
    done
  fi
}

hardhat_doctor_render_json() {
  local generated_at
  local ready
  local idx
  local item check_id result title details recommendation

  generated_at="$(hardhat_json_generated_at_utc)"
  ready="false"
  if [[ "${HARDHAT_DOCTOR_READY}" -eq 1 ]]; then
    ready="true"
  fi

  printf '{'
  hardhat_json_print_metadata "doctor" "${generated_at}"
  printf ','
  printf '"command":"doctor",'
  hardhat_json_print_status "${HARDHAT_DOCTOR_STATUS}" "${HARDHAT_DOCTOR_EXIT_CODE}" "${HARDHAT_DOCTOR_STATUS_MESSAGE}"
  printf ','

  printf '"summary":{'
  printf '"text":"%s",' "$(hardhat_json_escape "${HARDHAT_DOCTOR_SUMMARY}")"
  printf '"ready":%s,' "${ready}"
  printf '"total_checks":%s,' "${HARDHAT_DOCTOR_TOTAL_CHECKS}"
  printf '"pass":%s,' "${HARDHAT_DOCTOR_PASS_COUNT}"
  printf '"warn":%s,' "${HARDHAT_DOCTOR_WARN_COUNT}"
  printf '"fail":%s,' "${HARDHAT_DOCTOR_FAIL_COUNT}"
  printf '"info":%s' "${HARDHAT_DOCTOR_INFO_COUNT}"
  printf '},'

  printf '"notes":'
  hardhat_json_print_string_array "${HARDHAT_DOCTOR_NOTES[@]}"
  printf ','

  printf '"checks":['
  idx=0
  for item in "${HARDHAT_DOCTOR_CHECKS[@]}"; do
    IFS='|' read -r check_id result title details recommendation <<<"${item}"
    if ((idx > 0)); then
      printf ','
    fi
    printf '{'
    printf '"id":"%s",' "$(hardhat_json_escape "${check_id}")"
    printf '"result":"%s",' "$(hardhat_json_escape "${result}")"
    printf '"title":"%s",' "$(hardhat_json_escape "${title}")"
    printf '"details":"%s",' "$(hardhat_json_escape "${details}")"
    printf '"recommendation":'
    hardhat_json_nullable_string "${recommendation}"
    printf '}'
    idx=$((idx + 1))
  done
  printf '],'

  printf '"findings":[],'
  printf '"recommendations":'
  hardhat_json_print_string_array "${HARDHAT_DOCTOR_RECOMMENDATIONS[@]}"
  printf '}'
  printf '\n'
}

hardhat_doctor_render_json_usage_error() {
  local generated_at
  generated_at="$(hardhat_json_generated_at_utc)"

  printf '{'
  hardhat_json_print_metadata "doctor" "${generated_at}"
  printf ','
  printf '"command":"doctor",'
  hardhat_json_print_status "usage_error" "${HARDHAT_EXIT_USAGE}" "invalid doctor arguments"
  printf ','
  printf '"summary":null,'
  printf '"notes":[],'
  printf '"checks":[],'
  printf '"findings":[],'
  printf '"recommendations":[]'
  printf '}'
  printf '\n'
}

hardhat_module_doctor_validate_args() {
  local arg
  for arg in "$@"; do
    case "${arg}" in
      -h|--help|help)
        hardhat_module_doctor_usage
        return 2
        ;;
      --json)
        ;;
      *)
        if hardhat_doctor_is_spanish; then
          hardhat_log_error "Argumento no valido para doctor: ${arg}"
          hardhat_log_info "Usa 'hardhat doctor --help' para ver uso."
        else
          hardhat_log_error "Invalid argument for doctor: ${arg}"
          hardhat_log_info "Use 'hardhat doctor --help' for usage."
        fi
        return 1
        ;;
    esac
  done

  return 0
}

hardhat_module_doctor_collect() {
  HARDHAT_DOCTOR_CHECKS=()
  HARDHAT_DOCTOR_NOTES=()
  HARDHAT_DOCTOR_RECOMMENDATIONS=()

  hardhat_doctor_add_note "Doctor runs read-only diagnostics and does not modify system state."

  hardhat_doctor_collect_platform_check
  hardhat_doctor_collect_tools_checks
  hardhat_doctor_collect_runtime_checks
  hardhat_doctor_collect_context_checks
  hardhat_doctor_collect_recommendations
  hardhat_doctor_calculate_summary
}

hardhat_module_doctor_run() {
  local validate_status=0

  hardhat_module_doctor_validate_args "$@" || validate_status=$?
  if [[ "${validate_status}" -eq 2 ]]; then
    return "${HARDHAT_EXIT_SUCCESS}"
  fi
  if [[ "${validate_status}" -ne 0 ]]; then
    if hardhat_is_json_mode; then
      hardhat_doctor_render_json_usage_error
    else
      hardhat_module_doctor_usage
    fi
    return "${HARDHAT_EXIT_USAGE}"
  fi

  hardhat_module_doctor_collect

  if hardhat_is_json_mode; then
    hardhat_doctor_render_json
    return "${HARDHAT_DOCTOR_EXIT_CODE}"
  fi

  hardhat_doctor_render_human
  return "${HARDHAT_DOCTOR_EXIT_CODE}"
}
