#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT="/opt/hardhat"
BIN_DIR="/usr/local/bin"
TARGET_BIN="${BIN_DIR}/hardhat"
GLOBAL_CONFIG_DIR="/etc/hardhat"
GLOBAL_CONFIG_FILE="${GLOBAL_CONFIG_DIR}/config"
ASSUME_YES=0
DRY_RUN=0
PURGE_CONFIG=0
APP_LANG=""

msg() {
  local key="$1"

  if [[ "${APP_LANG:-en}" == "es" ]]; then
    case "${key}" in
      plan_title) printf 'Plan de desinstalacion:\n' ;;
      plan_runtime) printf '  Runtime:      %s\n' "${INSTALL_ROOT}" ;;
      plan_command) printf '  Comando:      %s\n' "${TARGET_BIN}" ;;
      plan_config_keep) printf '  Config global: conservar (%s)\n\n' "${GLOBAL_CONFIG_FILE}" ;;
      plan_config_purge) printf '  Config global: eliminar (%s)\n\n' "${GLOBAL_CONFIG_FILE}" ;;
      actions_title) printf 'Acciones:\n' ;;
      action_bin) printf '  1) Eliminar enlace/comando %s (si corresponde)\n' "${TARGET_BIN}" ;;
      action_root) printf '  2) Eliminar runtime %s\n' "${INSTALL_ROOT}" ;;
      action_cfg) printf '  3) Eliminar configuracion global (opcional)\n' ;;
      confirm_skipped) printf 'Confirmacion omitida por --yes\n' ;;
      confirm_prompt) printf 'Continuar con la desinstalacion? [y/N]: ' ;;
      cancelled) printf 'Desinstalacion cancelada.\n' ;;
      sudo_required) printf 'sudo es necesario para desinstalar si no ejecutas como root.\n' ;;
      dryrun_done) printf '\nDry-run completado. No se modificaron archivos.\n' ;;
      uninstall_done) printf '\nDesinstalacion completada.\n' ;;
      removed_root) printf 'Runtime eliminado: %s\n' "${INSTALL_ROOT}" ;;
      removed_bin) printf 'Comando eliminado: %s\n' "${TARGET_BIN}" ;;
      removed_cfg) printf 'Config global eliminada: %s\n' "${GLOBAL_CONFIG_FILE}" ;;
      kept_cfg) printf 'Config global conservada: %s\n' "${GLOBAL_CONFIG_FILE}" ;;
      skip_bin) printf 'Se omite %s porque no apunta a HardHat o no es symlink.\n' "${TARGET_BIN}" ;;
      skip_missing) printf 'No existe: %s\n' "$2" ;;
      *) return 1 ;;
    esac
    return 0
  fi

  case "${key}" in
    plan_title) printf 'Uninstall plan:\n' ;;
    plan_runtime) printf '  Runtime:      %s\n' "${INSTALL_ROOT}" ;;
    plan_command) printf '  Command:      %s\n' "${TARGET_BIN}" ;;
    plan_config_keep) printf '  Global config: keep (%s)\n\n' "${GLOBAL_CONFIG_FILE}" ;;
    plan_config_purge) printf '  Global config: remove (%s)\n\n' "${GLOBAL_CONFIG_FILE}" ;;
    actions_title) printf 'Actions:\n' ;;
    action_bin) printf '  1) Remove command/symlink %s (when appropriate)\n' "${TARGET_BIN}" ;;
    action_root) printf '  2) Remove runtime %s\n' "${INSTALL_ROOT}" ;;
    action_cfg) printf '  3) Remove global config (optional)\n' ;;
    confirm_skipped) printf 'Confirmation skipped by --yes\n' ;;
    confirm_prompt) printf 'Proceed with uninstall? [y/N]: ' ;;
    cancelled) printf 'Uninstall cancelled.\n' ;;
    sudo_required) printf 'sudo is required for uninstall when not running as root.\n' ;;
    dryrun_done) printf '\nDry-run complete. No files were changed.\n' ;;
    uninstall_done) printf '\nUninstall complete.\n' ;;
    removed_root) printf 'Runtime removed: %s\n' "${INSTALL_ROOT}" ;;
    removed_bin) printf 'Command removed: %s\n' "${TARGET_BIN}" ;;
    removed_cfg) printf 'Global config removed: %s\n' "${GLOBAL_CONFIG_FILE}" ;;
    kept_cfg) printf 'Global config kept: %s\n' "${GLOBAL_CONFIG_FILE}" ;;
    skip_bin) printf 'Skipping %s because it is not pointing to HardHat or not a symlink.\n' "${TARGET_BIN}" ;;
    skip_missing) printf 'Missing: %s\n' "$2" ;;
    *) return 1 ;;
  esac
}

uninstall_usage() {
  cat <<'EOF'
HardHat uninstaller

Usage:
  ./uninstall.sh [options]

Options:
  --yes                Skip confirmation prompt
  --dry-run            Show actions without changing files
  --purge-config       Remove /etc/hardhat/config and clean empty /etc/hardhat
  --install-root PATH  Runtime root to remove (default: /opt/hardhat)
  --bin-dir PATH       Directory with hardhat command (default: /usr/local/bin)
  --lang <en|es>       Message language override
  --help               Show this help
EOF
}

need_sudo() {
  [[ "${EUID}" -ne 0 ]]
}

run_as_root() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi

  if need_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --yes)
        ASSUME_YES=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      --purge-config)
        PURGE_CONFIG=1
        ;;
      --install-root)
        shift
        INSTALL_ROOT="${1:-}"
        ;;
      --bin-dir)
        shift
        BIN_DIR="${1:-}"
        ;;
      --lang)
        shift
        APP_LANG="${1:-}"
        ;;
      --help)
        uninstall_usage
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        uninstall_usage
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "${INSTALL_ROOT}" ]] || [[ -z "${BIN_DIR}" ]]; then
    printf 'install-root and bin-dir must be non-empty paths.\n' >&2
    exit 1
  fi

  if [[ -n "${APP_LANG}" ]] && [[ "${APP_LANG}" != "en" ]] && [[ "${APP_LANG}" != "es" ]]; then
    printf 'Unsupported language: %s (use en or es).\n' "${APP_LANG}" >&2
    exit 1
  fi

  TARGET_BIN="${BIN_DIR}/hardhat"
}

load_language_if_needed() {
  if [[ -n "${APP_LANG}" ]]; then
    return 0
  fi

  APP_LANG="en"
  if [[ -f "${GLOBAL_CONFIG_FILE}" ]]; then
    local value=""
    value="$(awk -F= '/^[[:space:]]*HARDHAT_LANG[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' "${GLOBAL_CONFIG_FILE}")"
    value="${value%\"}"
    value="${value#\"}"
    if [[ "${value}" == "es" ]] || [[ "${value}" == "en" ]]; then
      APP_LANG="${value}"
    fi
  fi
}

show_plan() {
  msg plan_title
  msg plan_runtime
  msg plan_command
  if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    msg plan_config_purge
  else
    msg plan_config_keep
  fi

  msg actions_title
  msg action_bin
  msg action_root
  if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    msg action_cfg
  fi
}

confirm_plan() {
  if [[ "${ASSUME_YES}" -eq 1 ]]; then
    msg confirm_skipped
    return 0
  fi

  local prompt answer
  prompt="$(msg confirm_prompt)"
  read -r -p "${prompt}" answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      msg cancelled
      return 1
      ;;
  esac
}

remove_command_if_owned() {
  if [[ ! -e "${TARGET_BIN}" ]]; then
    msg skip_missing "${TARGET_BIN}"
    return 0
  fi

  if [[ -L "${TARGET_BIN}" ]]; then
    local resolved=""
    resolved="$(readlink -f "${TARGET_BIN}" 2>/dev/null || true)"
    if [[ "${resolved}" == "${INSTALL_ROOT}/bin/hardhat" ]]; then
      run_as_root rm -f "${TARGET_BIN}"
      msg removed_bin
      return 0
    fi
  fi

  msg skip_bin
  return 0
}

remove_runtime() {
  if [[ -d "${INSTALL_ROOT}" ]]; then
    run_as_root rm -rf "${INSTALL_ROOT}"
    msg removed_root
  else
    msg skip_missing "${INSTALL_ROOT}"
  fi
}

purge_global_config_if_requested() {
  if [[ "${PURGE_CONFIG}" -ne 1 ]]; then
    msg kept_cfg
    return 0
  fi

  if [[ -f "${GLOBAL_CONFIG_FILE}" ]]; then
    run_as_root rm -f "${GLOBAL_CONFIG_FILE}"
    msg removed_cfg
  else
    msg skip_missing "${GLOBAL_CONFIG_FILE}"
  fi

  if [[ -d "${GLOBAL_CONFIG_DIR}" ]] && [[ -z "$(ls -A "${GLOBAL_CONFIG_DIR}" 2>/dev/null)" ]]; then
    run_as_root rmdir "${GLOBAL_CONFIG_DIR}" || true
  fi
}

main() {
  parse_args "$@"
  load_language_if_needed
  show_plan

  if ! confirm_plan; then
    exit 1
  fi

  if need_sudo && ! command -v sudo >/dev/null 2>&1; then
    msg sudo_required >&2
    exit 1
  fi

  remove_command_if_owned
  remove_runtime
  purge_global_config_if_requested

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    msg dryrun_done
    exit 0
  fi

  msg uninstall_done
}

main "$@"