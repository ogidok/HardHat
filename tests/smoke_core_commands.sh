#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT_DIR}/bin/hardhat"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

assert_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -Eiq "${pattern}" "${file}"; then
    echo "[fail] Expected pattern not found: ${pattern}" >&2
    echo "[fail] Output was:" >&2
    cat "${file}" >&2
    exit 1
  fi
}

assert_success() {
  local name="$1"
  shift
  local out_file="${TMP_DIR}/${name}.out"
  if ! "$@" >"${out_file}" 2>&1; then
    echo "[fail] Command should succeed: $*" >&2
    cat "${out_file}" >&2
    exit 1
  fi
}

json_is_parseable() {
  local file="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -e . "${file}" >/dev/null
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool <"${file}" >/dev/null
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    python -m json.tool <"${file}" >/dev/null
    return 0
  fi

  return 2
}

assert_json_parseable() {
  local file="$1"
  local status=0

  json_is_parseable "${file}" || status=$?
  if [[ "${status}" -eq 2 ]]; then
    assert_contains "${file}" '^\{'
    assert_contains "${file}" '"metadata"'
    echo "[warn] jq/python unavailable; applied heuristic JSON check"
    return 0
  fi

  if [[ "${status}" -ne 0 ]]; then
    echo "[fail] JSON is not parseable: ${file}" >&2
    cat "${file}" >&2
    exit 1
  fi
}

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "arch" ]] && [[ "${ID_LIKE:-}" != *"arch"* ]]; then
    echo "[skip] core smoke tests are scoped to Arch-first environments"
    exit 0
  fi
fi

echo "[smoke] core commands"

assert_success help_core "${BIN}" help
assert_contains "${TMP_DIR}/help_core.out" "HardHat"

assert_success audit_core "${BIN}" audit
assert_contains "${TMP_DIR}/audit_core.out" "Audit|Auditoria|Score|Resumen"

assert_success firewall_audit_core "${BIN}" firewall audit
assert_contains "${TMP_DIR}/firewall_audit_core.out" "firewall|UFW|Firewall"

assert_success firewall_apply_dryrun_core "${BIN}" firewall apply --dry-run --yes
assert_contains "${TMP_DIR}/firewall_apply_dryrun_core.out" "Dry-run|dry-run|Simula|simula"

TEST_ROOT="${TMP_DIR}/opt/hardhat"
TEST_BIN_DIR="${TMP_DIR}/usr/local/bin"
mkdir -p "${TEST_ROOT}/bin" "${TEST_BIN_DIR}"
: >"${TEST_ROOT}/bin/hardhat"
ln -s "${TEST_ROOT}/bin/hardhat" "${TEST_BIN_DIR}/hardhat"

assert_success uninstall_dryrun_core "${BIN}" uninstall --dry-run --yes --install-root "${TEST_ROOT}" --bin-dir "${TEST_BIN_DIR}"
assert_contains "${TMP_DIR}/uninstall_dryrun_core.out" "Dry-run|dry-run|Desinstalacion|Uninstall"

# JSON parseability checks for main operational commands.
"${BIN}" audit --json >"${TMP_DIR}/audit_json.out" 2>"${TMP_DIR}/audit_json.err"
assert_json_parseable "${TMP_DIR}/audit_json.out"

"${BIN}" firewall audit --json >"${TMP_DIR}/firewall_audit_json.out" 2>"${TMP_DIR}/firewall_audit_json.err"
assert_json_parseable "${TMP_DIR}/firewall_audit_json.out"

"${BIN}" --json firewall apply --dry-run --yes >"${TMP_DIR}/firewall_apply_json.out" 2>"${TMP_DIR}/firewall_apply_json.err"
assert_json_parseable "${TMP_DIR}/firewall_apply_json.out"

# uninstall currently does not define a JSON contract; keep behavior visible in test logs.
if "${BIN}" --json uninstall --dry-run --yes --install-root "${TEST_ROOT}" --bin-dir "${TEST_BIN_DIR}" >"${TMP_DIR}/uninstall_json.out" 2>"${TMP_DIR}/uninstall_json.err"; then
  echo "[info] uninstall --json returned success; JSON contract is still undefined"
else
  echo "[info] uninstall --json is currently unsupported (expected in current roadmap state)"
fi

echo "[ok] core commands smoke passed"
