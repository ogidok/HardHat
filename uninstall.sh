#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HARDHAT_LOCAL_BIN="${ROOT_DIR}/bin/hardhat"

printf '[DEPRECATED] Use "hardhat uninstall" as the primary uninstall path.\n' >&2

if command -v hardhat >/dev/null 2>&1; then
  exec hardhat uninstall "$@"
fi

if [[ -x "${HARDHAT_LOCAL_BIN}" ]]; then
  exec "${HARDHAT_LOCAL_BIN}" uninstall "$@"
fi

printf 'hardhat command not found and local bin/hardhat is missing.\n' >&2
printf 'Run uninstall manually:\n' >&2
printf '  sudo rm -f /usr/local/bin/hardhat\n' >&2
printf '  sudo rm -rf /opt/hardhat\n' >&2
exit 1