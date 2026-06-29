#!/usr/bin/env bash

HARDHAT_UNINSTALL_INSTALL_ROOT="/opt/hardhat"
HARDHAT_UNINSTALL_BIN_DIR="/usr/local/bin"
HARDHAT_UNINSTALL_TARGET_BIN="/usr/local/bin/hardhat"
HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR="/etc/hardhat"
HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE="/etc/hardhat/config"
HARDHAT_UNINSTALL_USER_CONFIG_DIR="${HOME}/.config/hardhat"
HARDHAT_UNINSTALL_USER_CONFIG_FILE="${HOME}/.config/hardhat/config"
HARDHAT_UNINSTALL_PURGE_CONFIG=0
HARDHAT_UNINSTALL_STATUS="unknown"
HARDHAT_UNINSTALL_STATUS_MESSAGE=""
HARDHAT_UNINSTALL_EXIT_CODE=0
HARDHAT_UNINSTALL_NOTES=()

hardhat_uninstall_msg() {
  local key="$1"

  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    case "${key}" in
      usage)
        cat <<'EOF'
HardHat uninstall - Desinstalacion segura

Uso:
  hardhat uninstall [opciones]

Descripcion:
  Elimina runtime y comando de HardHat. Solo borra el comando si apunta al runtime esperado.
  Este flujo esta orientado a instalaciones manuales/desarrollo.

Opciones:
  -h, --help          Muestra esta ayuda
  --yes               Omite confirmacion interactiva
  --dry-run           Muestra acciones sin modificar archivos
  --purge-config      Elimina configuracion global y de usuario
  --install-root PATH  Raiz runtime (default: /opt/hardhat)
  --bin-dir PATH       Directorio del comando (default: /usr/local/bin)
  --lang <en|es>       Sobrescribe idioma de mensajes

Ejemplos:
  hardhat uninstall --dry-run --yes
  hardhat uninstall --yes --purge-config
EOF
        ;;
      plan_title) printf 'Plan de desinstalacion:\n' ;;
      plan_runtime) printf '  Runtime:      %s\n' "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ;;
      plan_command) printf '  Comando:      %s\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
      plan_cfg_keep) printf '  Config:       conservar\n\n' ;;
      plan_cfg_purge) printf '  Config:       eliminar (global + usuario)\n\n' ;;
      actions_title) printf 'Acciones:\n' ;;
      action_bin) printf '  1) Eliminar enlace/comando si pertenece a HardHat\n' ;;
      action_root) printf '  2) Eliminar runtime\n' ;;
      action_cfg) printf '  3) Eliminar configuracion (opcional)\n' ;;
      confirm_prompt) printf 'Continuar con el plan de desinstalacion? [y/N]: ' ;;
      confirm_skipped) printf 'Confirmacion omitida (--yes).\n' ;;
      cancelled) printf 'Desinstalacion cancelada.\n' ;;
      sudo_required) printf 'Se requiere sudo/root para eliminar rutas del sistema.\n' ;;
      skip_missing) printf 'No existe: %s\n' "$2" ;;
      skip_bin) printf 'Se omite %s porque no apunta a runtime HardHat.\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
      removed_bin) printf 'Comando eliminado: %s\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
      removed_root) printf 'Runtime eliminado: %s\n' "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ;;
      removed_cfg_global) printf 'Config global eliminada: %s\n' "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}" ;;
      removed_cfg_user) printf 'Config usuario eliminada: %s\n' "${HARDHAT_UNINSTALL_USER_CONFIG_FILE}" ;;
      kept_cfg) printf 'Configuracion conservada.\n' ;;
      done) printf '\nDesinstalacion completada correctamente.\n' ;;
      dryrun_done) printf '\nDry-run completado. No se modificaron archivos.\n' ;;
      bad_lang) printf 'Idioma no soportado: %s (usa en o es).\n' "$2" ;;
      unknown_opt) printf 'Opcion desconocida para uninstall: %s (usa --help).\n' "$2" ;;
      missing_value) printf 'Falta valor para: %s\n' "$2" ;;
      *) return 1 ;;
    esac
    return 0
  fi

  case "${key}" in
    usage)
      cat <<'EOF'
HardHat uninstall - Safe uninstall

Usage:
  hardhat uninstall [options]

Description:
  Removes HardHat runtime and command. The command is removed only if it points to the expected runtime.
  This flow is intended for manual/development installs.

Options:
  -h, --help          Show this help
  --yes               Skip interactive confirmation
  --dry-run           Show actions without changing files
  --purge-config      Remove global and user configuration
  --install-root PATH  Runtime root (default: /opt/hardhat)
  --bin-dir PATH       Command directory (default: /usr/local/bin)
  --lang <en|es>       Override message language

Examples:
  hardhat uninstall --dry-run --yes
  hardhat uninstall --yes --purge-config
EOF
      ;;
    plan_title) printf 'Uninstall plan:\n' ;;
    plan_runtime) printf '  Runtime:      %s\n' "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ;;
    plan_command) printf '  Command:      %s\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
    plan_cfg_keep) printf '  Config:       keep\n\n' ;;
    plan_cfg_purge) printf '  Config:       remove (global + user)\n\n' ;;
    actions_title) printf 'Actions:\n' ;;
    action_bin) printf '  1) Remove command/symlink if owned by HardHat\n' ;;
    action_root) printf '  2) Remove runtime\n' ;;
    action_cfg) printf '  3) Remove configuration (optional)\n' ;;
    confirm_prompt) printf 'Proceed with uninstall plan? [y/N]: ' ;;
    confirm_skipped) printf 'Confirmation skipped (--yes).\n' ;;
    cancelled) printf 'Uninstall cancelled.\n' ;;
    sudo_required) printf 'sudo/root is required to remove system paths.\n' ;;
    skip_missing) printf 'Missing: %s\n' "$2" ;;
    skip_bin) printf 'Skipping %s because it is not pointing to HardHat runtime.\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
    removed_bin) printf 'Command removed: %s\n' "${HARDHAT_UNINSTALL_TARGET_BIN}" ;;
    removed_root) printf 'Runtime removed: %s\n' "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ;;
    removed_cfg_global) printf 'Global config removed: %s\n' "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}" ;;
    removed_cfg_user) printf 'User config removed: %s\n' "${HARDHAT_UNINSTALL_USER_CONFIG_FILE}" ;;
    kept_cfg) printf 'Configuration kept.\n' ;;
    done) printf '\nUninstall completed successfully.\n' ;;
    dryrun_done) printf '\nDry-run complete. No files were changed.\n' ;;
    bad_lang) printf 'Unsupported language: %s (use en or es).\n' "$2" ;;
    unknown_opt) printf 'Unknown uninstall option: %s (use --help).\n' "$2" ;;
    missing_value) printf 'Missing value for: %s\n' "$2" ;;
    *) return 1 ;;
  esac
}

hardhat_module_uninstall_usage() {
  hardhat_uninstall_msg usage
}

hardhat_uninstall_add_note() {
  HARDHAT_UNINSTALL_NOTES+=("$*")
}

hardhat_uninstall_render_json() {
  local generated_at
  generated_at="$(hardhat_json_generated_at_utc)"

  printf '{'
  hardhat_json_print_metadata "uninstall" "${generated_at}"
  printf ','
  printf '"command":"uninstall",'
  hardhat_json_print_status "${HARDHAT_UNINSTALL_STATUS}" "${HARDHAT_UNINSTALL_EXIT_CODE}" "${HARDHAT_UNINSTALL_STATUS_MESSAGE}"
  printf ','
  printf '"summary":{'
  printf '"dry_run":%s,' "$( [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]] && printf true || printf false )"
  printf '"purge_config":%s,' "$( [[ "${HARDHAT_UNINSTALL_PURGE_CONFIG}" -eq 1 ]] && printf true || printf false )"
  printf '"install_root":"%s",' "$(hardhat_json_escape "${HARDHAT_UNINSTALL_INSTALL_ROOT}")"
  printf '"bin_path":"%s"' "$(hardhat_json_escape "${HARDHAT_UNINSTALL_TARGET_BIN}")"
  printf '},'
  printf '"notes":'
  hardhat_json_print_string_array "${HARDHAT_UNINSTALL_NOTES[@]}"
  printf ','
  printf '"findings":[],'
  printf '"recommendations":[]'
  printf '}'
  printf '\n'
}

hardhat_uninstall_finish() {
  local status="$1"
  local message="$2"
  local exit_code="$3"

  HARDHAT_UNINSTALL_STATUS="${status}"
  HARDHAT_UNINSTALL_STATUS_MESSAGE="${message}"
  HARDHAT_UNINSTALL_EXIT_CODE="${exit_code}"

  if hardhat_is_json_mode; then
    hardhat_uninstall_render_json
  fi

  return "${exit_code}"
}

hardhat_module_uninstall_parse_args() {
  local -a args=("$@")
  local i=0
  local current

  HARDHAT_UNINSTALL_PURGE_CONFIG=0
  HARDHAT_UNINSTALL_INSTALL_ROOT="/opt/hardhat"
  HARDHAT_UNINSTALL_BIN_DIR="/usr/local/bin"
  HARDHAT_UNINSTALL_TARGET_BIN="${HARDHAT_UNINSTALL_BIN_DIR}/hardhat"
  HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR="/etc/hardhat"
  HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE="${HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR}/config"
  HARDHAT_UNINSTALL_USER_CONFIG_DIR="${HOME}/.config/hardhat"
  HARDHAT_UNINSTALL_USER_CONFIG_FILE="${HARDHAT_UNINSTALL_USER_CONFIG_DIR}/config"

  while ((i < ${#args[@]})); do
    current="${args[$i]}"
    case "${current}" in
      --purge-config)
        HARDHAT_UNINSTALL_PURGE_CONFIG=1
        ;;
      --install-root)
        i=$((i + 1))
        if ((i >= ${#args[@]})); then
          hardhat_log_error "$(hardhat_uninstall_msg missing_value --install-root)"
          return 1
        fi
        HARDHAT_UNINSTALL_INSTALL_ROOT="${args[$i]}"
        ;;
      --bin-dir)
        i=$((i + 1))
        if ((i >= ${#args[@]})); then
          hardhat_log_error "$(hardhat_uninstall_msg missing_value --bin-dir)"
          return 1
        fi
        HARDHAT_UNINSTALL_BIN_DIR="${args[$i]}"
        ;;
      --lang)
        i=$((i + 1))
        if ((i >= ${#args[@]})); then
          hardhat_log_error "$(hardhat_uninstall_msg missing_value --lang)"
          return 1
        fi
        if ! hardhat_validate_language_code "${args[$i]}"; then
          hardhat_log_error "$(hardhat_uninstall_msg bad_lang "${args[$i]}")"
          return 1
        fi
        HARDHAT_LANG="${args[$i]}"
        ;;
      --yes|--dry-run)
        ;;
      -h|--help|help)
        hardhat_module_uninstall_usage
        return 2
        ;;
      *)
        hardhat_log_error "$(hardhat_uninstall_msg unknown_opt "${current}")"
        return 1
        ;;
    esac
    i=$((i + 1))
  done

  HARDHAT_UNINSTALL_TARGET_BIN="${HARDHAT_UNINSTALL_BIN_DIR}/hardhat"

  if [[ -z "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ]] || [[ -z "${HARDHAT_UNINSTALL_BIN_DIR}" ]]; then
    if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
      hardhat_log_error "install-root y bin-dir deben ser rutas no vacias."
    else
      hardhat_log_error "install-root and bin-dir must be non-empty paths."
    fi
    return 1
  fi

  return 0
}

hardhat_module_uninstall_show_plan() {
  if hardhat_is_json_mode; then
    return 0
  fi

  hardhat_uninstall_msg plan_title
  hardhat_uninstall_msg plan_runtime
  hardhat_uninstall_msg plan_command
  if [[ "${HARDHAT_UNINSTALL_PURGE_CONFIG}" -eq 1 ]]; then
    hardhat_uninstall_msg plan_cfg_purge
  else
    hardhat_uninstall_msg plan_cfg_keep
  fi

  hardhat_uninstall_msg actions_title
  hardhat_uninstall_msg action_bin
  hardhat_uninstall_msg action_root
  if [[ "${HARDHAT_UNINSTALL_PURGE_CONFIG}" -eq 1 ]]; then
    hardhat_uninstall_msg action_cfg
  fi
}

hardhat_module_uninstall_confirm() {
  if [[ "${HARDHAT_ASSUME_YES:-0}" -eq 1 ]]; then
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg confirm_skipped
    fi
    hardhat_uninstall_add_note "Confirmation skipped by --yes."
    return 0
  fi

  local prompt answer
  prompt="$(hardhat_uninstall_msg confirm_prompt)"
  read -r -p "${prompt}" answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      if ! hardhat_is_json_mode; then
        hardhat_uninstall_msg cancelled
      fi
      hardhat_uninstall_add_note "Uninstall cancelled by user."
      return 1
      ;;
  esac
}

hardhat_module_uninstall_needs_system_privileges() {
  if [[ "${HARDHAT_UNINSTALL_INSTALL_ROOT}" == /opt/* ]] || [[ "${HARDHAT_UNINSTALL_BIN_DIR}" == /usr/* ]] || [[ "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR}" == /etc/* ]]; then
    return 0
  fi
  return 1
}

hardhat_module_uninstall_remove_command_if_owned() {
  if [[ ! -e "${HARDHAT_UNINSTALL_TARGET_BIN}" ]]; then
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg skip_missing "${HARDHAT_UNINSTALL_TARGET_BIN}"
    fi
    hardhat_uninstall_add_note "Command path missing: ${HARDHAT_UNINSTALL_TARGET_BIN}."
    return 0
  fi

  if [[ -L "${HARDHAT_UNINSTALL_TARGET_BIN}" ]]; then
    local resolved=""
    resolved="$(readlink -f "${HARDHAT_UNINSTALL_TARGET_BIN}" 2>/dev/null || true)"
    if [[ "${resolved}" == "${HARDHAT_UNINSTALL_INSTALL_ROOT}/bin/hardhat" ]]; then
      hardhat_sudo_run rm -f "${HARDHAT_UNINSTALL_TARGET_BIN}" || return 1
      if ! hardhat_is_json_mode; then
        hardhat_uninstall_msg removed_bin
      fi
      hardhat_uninstall_add_note "Removed command: ${HARDHAT_UNINSTALL_TARGET_BIN}."
      return 0
    fi
  fi

  if ! hardhat_is_json_mode; then
    hardhat_uninstall_msg skip_bin
  fi
  hardhat_uninstall_add_note "Skipped command removal (path not owned by HardHat runtime)."
  return 0
}

hardhat_module_uninstall_remove_runtime() {
  if [[ -d "${HARDHAT_UNINSTALL_INSTALL_ROOT}" ]]; then
    hardhat_sudo_run rm -rf "${HARDHAT_UNINSTALL_INSTALL_ROOT}" || return 1
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg removed_root
    fi
    hardhat_uninstall_add_note "Removed runtime: ${HARDHAT_UNINSTALL_INSTALL_ROOT}."
  else
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg skip_missing "${HARDHAT_UNINSTALL_INSTALL_ROOT}"
    fi
    hardhat_uninstall_add_note "Runtime path missing: ${HARDHAT_UNINSTALL_INSTALL_ROOT}."
  fi
}

hardhat_module_uninstall_purge_config_if_requested() {
  if [[ "${HARDHAT_UNINSTALL_PURGE_CONFIG}" -ne 1 ]]; then
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg kept_cfg
    fi
    hardhat_uninstall_add_note "Configuration kept."
    return 0
  fi

  if [[ -f "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}" ]]; then
    hardhat_sudo_run rm -f "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}" || return 1
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg removed_cfg_global
    fi
    hardhat_uninstall_add_note "Removed global config: ${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}."
  else
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg skip_missing "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}"
    fi
    hardhat_uninstall_add_note "Global config missing: ${HARDHAT_UNINSTALL_GLOBAL_CONFIG_FILE}."
  fi

  if [[ -d "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR}" ]]; then
    if [[ -z "$(ls -A "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR}" 2>/dev/null)" ]]; then
      hardhat_sudo_run rmdir "${HARDHAT_UNINSTALL_GLOBAL_CONFIG_DIR}" || true
    fi
  fi

  if [[ -f "${HARDHAT_UNINSTALL_USER_CONFIG_FILE}" ]]; then
    rm -f "${HARDHAT_UNINSTALL_USER_CONFIG_FILE}"
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg removed_cfg_user
    fi
    hardhat_uninstall_add_note "Removed user config: ${HARDHAT_UNINSTALL_USER_CONFIG_FILE}."
  else
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg skip_missing "${HARDHAT_UNINSTALL_USER_CONFIG_FILE}"
    fi
    hardhat_uninstall_add_note "User config missing: ${HARDHAT_UNINSTALL_USER_CONFIG_FILE}."
  fi

  if [[ -d "${HARDHAT_UNINSTALL_USER_CONFIG_DIR}" ]]; then
    if [[ -z "$(ls -A "${HARDHAT_UNINSTALL_USER_CONFIG_DIR}" 2>/dev/null)" ]]; then
      rmdir "${HARDHAT_UNINSTALL_USER_CONFIG_DIR}" || true
    fi
  fi
}

hardhat_module_uninstall_run() {
  local parse_status=0
  HARDHAT_UNINSTALL_NOTES=()

  hardhat_module_uninstall_parse_args "$@" || parse_status=$?
  if [[ "${parse_status}" -eq 2 ]]; then
    return "${HARDHAT_EXIT_SUCCESS}"
  fi
  if [[ "${parse_status}" -ne 0 ]]; then
    if hardhat_is_json_mode; then
      hardhat_uninstall_finish "usage_error" "invalid uninstall arguments" "${HARDHAT_EXIT_USAGE}"
      return $?
    fi
    hardhat_module_uninstall_usage
    return "${HARDHAT_EXIT_USAGE}"
  fi

  hardhat_uninstall_add_note "Prepared uninstall plan."

  hardhat_module_uninstall_show_plan

  if [[ "${HARDHAT_DRY_RUN:-0}" -ne 1 ]] && hardhat_module_uninstall_needs_system_privileges; then
    if ! hardhat_require_elevated_or_sudo; then
      if ! hardhat_is_json_mode; then
        hardhat_uninstall_msg sudo_required
      fi
      hardhat_uninstall_add_note "Missing required privileges for system paths."
      hardhat_uninstall_finish "failed" "missing required privileges" "${HARDHAT_EXIT_OPERATIONAL}"
      return $?
    fi
  fi

  if ! hardhat_module_uninstall_confirm; then
    hardhat_uninstall_finish "aborted" "user cancelled uninstall" "${HARDHAT_EXIT_ABORTED}"
    return $?
  fi

  hardhat_module_uninstall_remove_command_if_owned || {
    hardhat_uninstall_finish "failed" "failed to remove command path" "${HARDHAT_EXIT_OPERATIONAL}"
    return $?
  }
  hardhat_module_uninstall_remove_runtime || {
    hardhat_uninstall_finish "failed" "failed to remove runtime path" "${HARDHAT_EXIT_OPERATIONAL}"
    return $?
  }
  hardhat_module_uninstall_purge_config_if_requested || {
    hardhat_uninstall_finish "failed" "failed while processing configuration cleanup" "${HARDHAT_EXIT_OPERATIONAL}"
    return $?
  }

  if [[ "${HARDHAT_DRY_RUN:-0}" -eq 1 ]]; then
    if ! hardhat_is_json_mode; then
      hardhat_uninstall_msg dryrun_done
    fi
    hardhat_uninstall_add_note "Dry-run completed; no files were changed."
    hardhat_uninstall_finish "dry-run" "dry-run completed" "${HARDHAT_EXIT_SUCCESS}"
    return $?
  fi

  if ! hardhat_is_json_mode; then
    hardhat_uninstall_msg done
  fi
  hardhat_uninstall_add_note "Uninstall completed."
  hardhat_uninstall_finish "success" "uninstall completed" "${HARDHAT_EXIT_SUCCESS}"
  return $?
}
