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

assert_json_contract_minimal() {
  local file="$1"
  assert_contains "${file}" '"metadata"'
  assert_contains "${file}" '"command"'
  assert_contains "${file}" '"status"'
  assert_contains "${file}" '"summary"'
  assert_contains "${file}" '"notes"'
  assert_contains "${file}" '"recommendations"'
}

assert_exit_code() {
  local expected="$1"
  shift
  local out_file="$1"
  shift
  local err_file="$1"
  shift
  local rc=0

  "$@" >"${out_file}" 2>"${err_file}" || rc=$?
  if [[ "${rc}" -ne "${expected}" ]]; then
    echo "[fail] Expected exit code ${expected}, got ${rc}: $*" >&2
    echo "[fail] stdout:" >&2
    cat "${out_file}" >&2 || true
    echo "[fail] stderr:" >&2
    cat "${err_file}" >&2 || true
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

assert_success setup_dryrun_core "${BIN}" setup --dry-run --yes
assert_contains "${TMP_DIR}/setup_dryrun_core.out" "setup|Setup|Dry-run|dry-run"

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
assert_json_contract_minimal "${TMP_DIR}/audit_json.out"
if [[ -s "${TMP_DIR}/audit_json.err" ]]; then
  assert_contains "${TMP_DIR}/audit_json.err" '^\[|ERROR|WARN|INFO|OK'
fi

"${BIN}" firewall audit --json >"${TMP_DIR}/firewall_audit_json.out" 2>"${TMP_DIR}/firewall_audit_json.err"
assert_json_parseable "${TMP_DIR}/firewall_audit_json.out"
assert_json_contract_minimal "${TMP_DIR}/firewall_audit_json.out"
if [[ -s "${TMP_DIR}/firewall_audit_json.err" ]]; then
  assert_contains "${TMP_DIR}/firewall_audit_json.err" '^\[|ERROR|WARN|INFO|OK'
fi

"${BIN}" --json firewall apply --dry-run --yes >"${TMP_DIR}/firewall_apply_json.out" 2>"${TMP_DIR}/firewall_apply_json.err"
assert_json_parseable "${TMP_DIR}/firewall_apply_json.out"
assert_json_contract_minimal "${TMP_DIR}/firewall_apply_json.out"
if [[ -s "${TMP_DIR}/firewall_apply_json.err" ]]; then
  assert_contains "${TMP_DIR}/firewall_apply_json.err" '^\[|ERROR|WARN|INFO|OK'
fi

"${BIN}" --json setup --dry-run --yes >"${TMP_DIR}/setup_json.out" 2>"${TMP_DIR}/setup_json.err"
assert_json_parseable "${TMP_DIR}/setup_json.out"
assert_json_contract_minimal "${TMP_DIR}/setup_json.out"
assert_contains "${TMP_DIR}/setup_json.out" '"command":"setup"'
if [[ -s "${TMP_DIR}/setup_json.err" ]]; then
  assert_contains "${TMP_DIR}/setup_json.err" '^\[|ERROR|WARN|INFO|OK'
fi

"${BIN}" --json uninstall --dry-run --yes --install-root "${TEST_ROOT}" --bin-dir "${TEST_BIN_DIR}" >"${TMP_DIR}/uninstall_json.out" 2>"${TMP_DIR}/uninstall_json.err"
assert_json_parseable "${TMP_DIR}/uninstall_json.out"
assert_json_contract_minimal "${TMP_DIR}/uninstall_json.out"
if [[ -s "${TMP_DIR}/uninstall_json.err" ]]; then
  assert_contains "${TMP_DIR}/uninstall_json.err" '^\[|ERROR|WARN|INFO|OK'
fi

# Exit code contract checks.
assert_exit_code 2 "${TMP_DIR}/audit_usage.out" "${TMP_DIR}/audit_usage.err" "${BIN}" --json audit --bogus
assert_json_parseable "${TMP_DIR}/audit_usage.out"
assert_contains "${TMP_DIR}/audit_usage.out" '"result":"usage_error"'

assert_exit_code 2 "${TMP_DIR}/fw_usage.out" "${TMP_DIR}/fw_usage.err" "${BIN}" --json firewall nope
assert_json_parseable "${TMP_DIR}/fw_usage.out"
assert_contains "${TMP_DIR}/fw_usage.out" '"result":"usage_error"'

assert_exit_code 2 "${TMP_DIR}/setup_usage.out" "${TMP_DIR}/setup_usage.err" "${BIN}" --json setup --bogus
assert_json_parseable "${TMP_DIR}/setup_usage.out"
assert_contains "${TMP_DIR}/setup_usage.out" '"command":"setup"'
assert_contains "${TMP_DIR}/setup_usage.out" '"result":"usage_error"'

assert_exit_code 30 "${TMP_DIR}/uninstall_abort.out" "${TMP_DIR}/uninstall_abort.err" sh -c "printf 'n\n' | \"${BIN}\" --json uninstall --install-root \"${TEST_ROOT}\" --bin-dir \"${TEST_BIN_DIR}\""
assert_json_parseable "${TMP_DIR}/uninstall_abort.out"
assert_contains "${TMP_DIR}/uninstall_abort.out" '"result":"aborted"'

echo "[ok] core commands smoke passed"
