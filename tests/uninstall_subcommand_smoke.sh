#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/hardhat"

TMP_BASE="$(mktemp -d)"
trap 'rm -rf "${TMP_BASE}"' EXIT

TEST_ROOT="${TMP_BASE}/opt/hardhat"
TEST_BIN_DIR="${TMP_BASE}/usr/local/bin"
mkdir -p "${TEST_ROOT}/bin" "${TEST_BIN_DIR}"

# Simulate expected hardhat symlink target ownership.
: >"${TEST_ROOT}/bin/hardhat"
ln -s "${TEST_ROOT}/bin/hardhat" "${TEST_BIN_DIR}/hardhat"

echo "[smoke] uninstall dry-run"
"${BIN}" uninstall \
  --dry-run \
  --yes \
  --purge-config \
  --install-root "${TEST_ROOT}" \
  --bin-dir "${TEST_BIN_DIR}" >/dev/null

echo "[ok] uninstall dry-run smoke passed"
