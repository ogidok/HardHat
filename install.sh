#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}"

INSTALL_ROOT="/opt/hardhat"
BIN_DIR="/usr/local/bin"
TARGET_BIN="${BIN_DIR}/hardhat"
ASSUME_YES=0
DRY_RUN=0
APP_LANG=""
GLOBAL_CONFIG_DIR="/etc/hardhat"
GLOBAL_CONFIG_FILE="/etc/hardhat/config"
USER_CONFIG_DIR="${HOME}/.config/hardhat"
USER_CONFIG_FILE="${USER_CONFIG_DIR}/config"
BANNER_FILE="${ROOT_DIR}/accsi.txt"
BANNER_SECONDS=2

msg() {
  local key="$1"

  if [[ "${APP_LANG:-en}" == "es" ]]; then
    case "${key}" in
      lang_default_yes) printf 'Idioma no definido. Se usa en por --yes.\n' ;;
      plan_title) printf 'Plan de instalacion:\n' ;;
      plan_source_root) printf '  Raiz origen:    %s\n' "${ROOT_DIR}" ;;
      plan_install_root) printf '  Raiz destino:   %s\n' "${INSTALL_ROOT}" ;;
      plan_command_path) printf '  Ruta comando:   %s\n\n' "${TARGET_BIN}" ;;
      plan_actions) printf 'Acciones:\n' ;;
      plan_action_1) printf '  1) Crear %s\n' "${INSTALL_ROOT}" ;;
      plan_action_2) printf '  2) Copiar bin/, lib/ y modules/ dentro de %s\n' "${INSTALL_ROOT}" ;;
      plan_action_3) printf '  3) Copiar accsi.txt dentro de %s\n' "${INSTALL_ROOT}" ;;
      plan_action_4) printf '  4) Crear symlink %s -> %s/bin/hardhat\n' "${TARGET_BIN}" "${INSTALL_ROOT}" ;;
      plan_action_5) printf '  5) Guardar idioma global en %s (%s)\n' "${GLOBAL_CONFIG_FILE}" "${APP_LANG}" ;;
      plan_action_6) printf '  6) Guardar idioma de usuario en %s (%s)\n' "${USER_CONFIG_FILE}" "${APP_LANG}" ;;
      confirm_skipped) printf 'Confirmacion omitida por --yes\n' ;;
      confirm_prompt) printf 'Continuar con la instalacion? [y/N]: ' ;;
      install_cancelled) printf 'Instalacion cancelada.\n' ;;
      sudo_required) printf 'sudo es necesario para instalar si no ejecutas como root.\n' ;;
      dryrun_write) printf '[dry-run] escribir %s con HARDHAT_LANG=%s\n' "${GLOBAL_CONFIG_FILE}" "${APP_LANG}" ;;
      dryrun_write_user) printf '[dry-run] escribir %s con HARDHAT_LANG=%s\n' "${USER_CONFIG_FILE}" "${APP_LANG}" ;;
      dryrun_done) printf '\nDry-run completado. No se modificaron archivos.\n' ;;
      install_done) printf '\nInstalacion completada.\n' ;;
      run_help) printf 'Ejecuta: hardhat --help\n' ;;
      installed_root) printf 'Raiz instalada: %s\n' "${INSTALL_ROOT}" ;;
      installed_cmd) printf 'Comando instalado: %s\n' "${TARGET_BIN}" ;;
      configured_lang) printf 'Idioma configurado: %s\n' "${APP_LANG}" ;;
      configured_lang_user) printf 'Idioma de usuario configurado: %s\n' "${APP_LANG}" ;;
      lang_select_title) printf 'Selecciona el idioma de la app:\n' ;;
      lang_select_opt_1) printf '  1) English (en)\n' ;;
      lang_select_opt_2) printf '  2) Espanol (es)\n' ;;
      lang_select_prompt) printf 'Opcion [1/2] (default 1): ' ;;
      *) return 1 ;;
    esac
    return 0
  fi

  case "${key}" in
    lang_default_yes) printf 'Language not provided. Defaulting to en due to --yes.\n' ;;
    plan_title) printf 'Install plan:\n' ;;
    plan_source_root) printf '  Source root:    %s\n' "${ROOT_DIR}" ;;
    plan_install_root) printf '  Install root:   %s\n' "${INSTALL_ROOT}" ;;
    plan_command_path) printf '  Command path:   %s\n\n' "${TARGET_BIN}" ;;
    plan_actions) printf 'Actions:\n' ;;
    plan_action_1) printf '  1) Create %s\n' "${INSTALL_ROOT}" ;;
    plan_action_2) printf '  2) Copy bin/, lib/ and modules/ into %s\n' "${INSTALL_ROOT}" ;;
    plan_action_3) printf '  3) Copy accsi.txt into %s\n' "${INSTALL_ROOT}" ;;
    plan_action_4) printf '  4) Create symlink %s -> %s/bin/hardhat\n' "${TARGET_BIN}" "${INSTALL_ROOT}" ;;
    plan_action_5) printf '  5) Persist global app language in %s (%s)\n' "${GLOBAL_CONFIG_FILE}" "${APP_LANG}" ;;
    plan_action_6) printf '  6) Persist user app language in %s (%s)\n' "${USER_CONFIG_FILE}" "${APP_LANG}" ;;
    confirm_skipped) printf 'Confirmation skipped by --yes\n' ;;
    confirm_prompt) printf 'Proceed with installation? [y/N]: ' ;;
    install_cancelled) printf 'Installation cancelled.\n' ;;
    sudo_required) printf 'sudo is required for installation when not running as root.\n' ;;
    dryrun_write) printf '[dry-run] write %s with HARDHAT_LANG=%s\n' "${GLOBAL_CONFIG_FILE}" "${APP_LANG}" ;;
    dryrun_write_user) printf '[dry-run] write %s with HARDHAT_LANG=%s\n' "${USER_CONFIG_FILE}" "${APP_LANG}" ;;
    dryrun_done) printf '\nDry-run complete. No files were changed.\n' ;;
    install_done) printf '\nInstallation complete.\n' ;;
    run_help) printf 'Run: hardhat --help\n' ;;
    installed_root) printf 'Installed runtime root: %s\n' "${INSTALL_ROOT}" ;;
    installed_cmd) printf 'Installed command path: %s\n' "${TARGET_BIN}" ;;
    configured_lang) printf 'Configured language: %s\n' "${APP_LANG}" ;;
    configured_lang_user) printf 'Configured user language: %s\n' "${APP_LANG}" ;;
    lang_select_title) printf 'Select app language:\n' ;;
    lang_select_opt_1) printf '  1) English (en)\n' ;;
    lang_select_opt_2) printf '  2) Espanol (es)\n' ;;
    lang_select_prompt) printf 'Choice [1/2] (default 1): ' ;;
    *) return 1 ;;
  esac
}

show_ascii_banner() {
  [[ -f "${BANNER_FILE}" ]] || return 0
  if [[ -t 1 ]]; then
    printf '\033[31m'
    cat "${BANNER_FILE}"
    printf '\033[0m'
  else
    cat "${BANNER_FILE}"
  fi
  printf '\n'
  sleep "${BANNER_SECONDS}"
}

install_usage() {
  cat <<'EOF'
HardHat installer

Usage:
  ./install.sh [options]

Options:
  --yes                Skip confirmation prompt
  --dry-run            Show actions without changing files
  --install-root PATH  Target runtime root (default: /opt/hardhat)
  --bin-dir PATH       Directory for hardhat command (default: /usr/local/bin)
  --lang <en|es>       App language to persist in global config
  --help               Show this help

This installer copies runtime files (bin/lib/modules) and creates a system
command symlink so `hardhat` can run from anywhere.
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
        install_usage
        exit 0
        ;;
      *)
        printf 'Unknown option: %s\n' "$1" >&2
        install_usage
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

select_language_if_needed() {
  if [[ -n "${APP_LANG}" ]]; then
    return 0
  fi

  if [[ "${ASSUME_YES}" -eq 1 ]]; then
    APP_LANG="en"
    msg lang_default_yes
    return 0
  fi

  msg lang_select_title
  msg lang_select_opt_1
  msg lang_select_opt_2
  local prompt
  prompt="$(msg lang_select_prompt)"
  read -r -p "${prompt}" lang_choice
  case "${lang_choice}" in
    2)
      APP_LANG="es"
      ;;
    *)
      APP_LANG="en"
      ;;
  esac
}

validate_source_tree() {
  if [[ ! -f "${ROOT_DIR}/bin/hardhat" ]]; then
    printf 'Missing source file: %s\n' "${ROOT_DIR}/bin/hardhat" >&2
    exit 1
  fi
  if [[ ! -f "${ROOT_DIR}/accsi.txt" ]]; then
    printf 'Missing source file: %s\n' "${ROOT_DIR}/accsi.txt" >&2
    exit 1
  fi
  if [[ ! -d "${ROOT_DIR}/lib" ]] || [[ ! -d "${ROOT_DIR}/modules" ]]; then
    printf 'Missing runtime directories (lib/modules) under %s\n' "${ROOT_DIR}" >&2
    exit 1
  fi
}

show_plan() {
  msg plan_title
  msg plan_source_root
  msg plan_install_root
  msg plan_command_path
  msg plan_actions
  msg plan_action_1
  msg plan_action_2
  msg plan_action_3
  msg plan_action_4
  msg plan_action_5
  msg plan_action_6
}

confirm_plan() {
  if [[ "${ASSUME_YES}" -eq 1 ]]; then
    msg confirm_skipped
    return 0
  fi

  local prompt
  prompt="$(msg confirm_prompt)"
  read -r -p "${prompt}" answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      msg install_cancelled
      return 1
      ;;
  esac
}

perform_install() {
  run_as_root mkdir -p "${INSTALL_ROOT}" "${BIN_DIR}"

  run_as_root rm -rf "${INSTALL_ROOT}/bin" "${INSTALL_ROOT}/lib" "${INSTALL_ROOT}/modules"
  run_as_root cp -a "${ROOT_DIR}/bin" "${INSTALL_ROOT}/bin"
  run_as_root cp -a "${ROOT_DIR}/lib" "${INSTALL_ROOT}/lib"
  run_as_root cp -a "${ROOT_DIR}/modules" "${INSTALL_ROOT}/modules"
  run_as_root cp -a "${ROOT_DIR}/accsi.txt" "${INSTALL_ROOT}/accsi.txt"

  run_as_root chmod +x "${INSTALL_ROOT}/bin/hardhat"
  run_as_root ln -sfn "${INSTALL_ROOT}/bin/hardhat" "${TARGET_BIN}"

  run_as_root mkdir -p "${GLOBAL_CONFIG_DIR}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    msg dryrun_write
    msg dryrun_write_user
  else
    local tmp_file
    tmp_file="$(mktemp)"
    printf 'HARDHAT_LANG=%s\n' "${APP_LANG}" >"${tmp_file}"
    run_as_root install -m 0644 "${tmp_file}" "${GLOBAL_CONFIG_FILE}"
    rm -f "${tmp_file}"

    mkdir -p "${USER_CONFIG_DIR}"
    printf 'HARDHAT_LANG=%s\n' "${APP_LANG}" >"${USER_CONFIG_FILE}"
  fi
}

main() {
  parse_args "$@"
  validate_source_tree
  show_ascii_banner
  select_language_if_needed
  show_plan

  if ! confirm_plan; then
    exit 1
  fi

  if need_sudo && ! command -v sudo >/dev/null 2>&1; then
    msg sudo_required >&2
    exit 1
  fi

  perform_install

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    msg dryrun_done
    exit 0
  fi

  msg install_done
  msg run_help
  msg installed_root
  msg installed_cmd
  msg configured_lang
  msg configured_lang_user
}

main "$@"