#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_BIN="/usr/local/bin/hardhat"

printf 'Installing HardHat into %s\n' "${TARGET_BIN}"

if [[ "${EUID}" -eq 0 ]]; then
  install -m 0755 "${ROOT_DIR}/bin/hardhat" "${TARGET_BIN}"
else
  sudo install -m 0755 "${ROOT_DIR}/bin/hardhat" "${TARGET_BIN}"
fi

printf 'Installed. Run: hardhat --help\n'