#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

INSTALL_ROOT="/opt/hardhat"
BIN_DIR="/usr/local/bin"
TARGET_BIN="${BIN_DIR}/hardhat"
ASSUME_YES=0
DRY_RUN=0
APP_LANG=""
GLOBAL_CONFIG_DIR="/etc/hardhat"
GLOBAL_CONFIG_FILE="/etc/hardhat/config"

install_usage() {
  cat <<'EOF'
HardHat installer

Usage:
  ./installers/install.sh [options]

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
    printf 'Language not provided. Defaulting to en due to --yes.\n'
    return 0
  fi

  printf 'Select app language:\n'
  printf '  1) English (en)\n'
  printf '  2) Espanol (es)\n'
  read -r -p 'Choice [1/2] (default 1): ' lang_choice
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
  if [[ ! -d "${ROOT_DIR}/lib" ]] || [[ ! -d "${ROOT_DIR}/modules" ]]; then
    printf 'Missing runtime directories (lib/modules) under %s\n' "${ROOT_DIR}" >&2
    exit 1
  fi
}

show_plan() {
  cat <<EOF
Install plan:
  Source root:    ${ROOT_DIR}
  Install root:   ${INSTALL_ROOT}
  Command path:   ${TARGET_BIN}

Actions:
  1) Create ${INSTALL_ROOT}
  2) Copy bin/, lib/ and modules/ into ${INSTALL_ROOT}
  3) Create symlink ${TARGET_BIN} -> ${INSTALL_ROOT}/bin/hardhat
  4) Persist global app language in ${GLOBAL_CONFIG_FILE} (${APP_LANG})
EOF
}

confirm_plan() {
  if [[ "${ASSUME_YES}" -eq 1 ]]; then
    printf 'Confirmation skipped by --yes\n'
    return 0
  fi

  read -r -p "Proceed with installation? [y/N]: " answer
  case "${answer}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      printf 'Installation cancelled.\n'
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

  run_as_root chmod +x "${INSTALL_ROOT}/bin/hardhat"
  run_as_root ln -sfn "${INSTALL_ROOT}/bin/hardhat" "${TARGET_BIN}"

  run_as_root mkdir -p "${GLOBAL_CONFIG_DIR}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '[dry-run] write %s with HARDHAT_LANG=%s\n' "${GLOBAL_CONFIG_FILE}" "${APP_LANG}"
  else
    local tmp_file
    tmp_file="$(mktemp)"
    printf 'HARDHAT_LANG=%s\n' "${APP_LANG}" >"${tmp_file}"
    run_as_root install -m 0644 "${tmp_file}" "${GLOBAL_CONFIG_FILE}"
    rm -f "${tmp_file}"
  fi
}

main() {
  parse_args "$@"
  validate_source_tree
  select_language_if_needed
  show_plan

  if ! confirm_plan; then
    exit 1
  fi

  if need_sudo && ! command -v sudo >/dev/null 2>&1; then
    printf 'sudo is required for installation when not running as root.\n' >&2
    exit 1
  fi

  perform_install

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf '\nDry-run complete. No files were changed.\n'
    exit 0
  fi

  printf '\nInstallation complete.\n'
  printf 'Run: hardhat --help\n'
  printf 'Installed runtime root: %s\n' "${INSTALL_ROOT}"
  printf 'Installed command path: %s\n' "${TARGET_BIN}"
  printf 'Configured language: %s\n' "${APP_LANG}"
}

main "$@"