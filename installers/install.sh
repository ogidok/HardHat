#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

INSTALL_ROOT="/opt/hardhat"
BIN_DIR="/usr/local/bin"
TARGET_BIN="${BIN_DIR}/hardhat"
ASSUME_YES=0
DRY_RUN=0

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

  TARGET_BIN="${BIN_DIR}/hardhat"
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
}

main() {
  parse_args "$@"
  validate_source_tree
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
}

main "$@"