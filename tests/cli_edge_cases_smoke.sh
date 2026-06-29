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

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Eiq "${pattern}" "${file}"; then
    echo "[fail] Unexpected pattern found: ${pattern}" >&2
    echo "[fail] Output was:" >&2
    cat "${file}" >&2
    exit 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local out_file="$2"
  local err_file="$3"
  shift 3

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

assert_json_parseable() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -e . "${file}" >/dev/null || {
      echo "[fail] JSON is not parseable via jq: ${file}" >&2
      cat "${file}" >&2
      exit 1
    }
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool <"${file}" >/dev/null || {
      echo "[fail] JSON is not parseable via python3: ${file}" >&2
      cat "${file}" >&2
      exit 1
    }
    return 0
  fi

  assert_contains "${file}" '^\{'
  assert_contains "${file}" '"metadata"'
}

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "arch" ]] && [[ "${ID_LIKE:-}" != *"arch"* ]]; then
    echo "[skip] cli edge cases are scoped to Arch-first environments"
    exit 0
  fi
fi

echo "[smoke] cli edge cases"

# Help/subhelp coverage additions.
assert_exit_code 0 "${TMP_DIR}/help_audit.out" "${TMP_DIR}/help_audit.err" "${BIN}" help audit
assert_contains "${TMP_DIR}/help_audit.out" "hardhat audit"

assert_exit_code 0 "${TMP_DIR}/help_uninstall.out" "${TMP_DIR}/help_uninstall.err" "${BIN}" help uninstall
assert_contains "${TMP_DIR}/help_uninstall.out" "hardhat uninstall"

assert_exit_code 0 "${TMP_DIR}/firewall_help.out" "${TMP_DIR}/firewall_help.err" "${BIN}" firewall help
assert_contains "${TMP_DIR}/firewall_help.out" "hardhat firewall"

# Invalid global flag should be usage error (2).
assert_exit_code 2 "${TMP_DIR}/global_invalid.out" "${TMP_DIR}/global_invalid.err" "${BIN}" --bogus
assert_contains "${TMP_DIR}/global_invalid.err" "Unknown option|Opcion desconocida"

# language show with extra args should be usage error (2).
assert_exit_code 2 "${TMP_DIR}/lang_show_extra.out" "${TMP_DIR}/lang_show_extra.err" "${BIN}" language show extra
assert_contains "${TMP_DIR}/lang_show_extra.err" "show"

# menu behavior in non-TTY and incompatible json mode.
assert_exit_code 20 "${TMP_DIR}/menu_notty.out" "${TMP_DIR}/menu_notty.err" sh -c "printf '7\n' | \"${BIN}\" menu"
assert_contains "${TMP_DIR}/menu_notty.err" "TTY|terminal"

assert_exit_code 2 "${TMP_DIR}/menu_json.out" "${TMP_DIR}/menu_json.err" "${BIN}" --json menu
assert_contains "${TMP_DIR}/menu_json.err" "not compatible|no es compatible"

# firewall apply dry-run variants.
assert_exit_code 0 "${TMP_DIR}/fw_apply_dryrun.out" "${TMP_DIR}/fw_apply_dryrun.err" "${BIN}" firewall apply --dry-run --yes
assert_contains "${TMP_DIR}/fw_apply_dryrun.out" "Dry-run|dry-run|Plan"

assert_exit_code 0 "${TMP_DIR}/fw_apply_dryrun_json.out" "${TMP_DIR}/fw_apply_dryrun_json.err" "${BIN}" --json firewall apply --dry-run --yes
assert_json_parseable "${TMP_DIR}/fw_apply_dryrun_json.out"
assert_contains "${TMP_DIR}/fw_apply_dryrun_json.out" '"command":"firewall apply"'
assert_contains "${TMP_DIR}/fw_apply_dryrun_json.out" '"result":"dry-run"'
assert_not_contains "${TMP_DIR}/fw_apply_dryrun_json.out" '\[INFO\]|\[WARN\]|\[ERROR\]'

assert_exit_code 2 "${TMP_DIR}/fw_apply_invalid_json.out" "${TMP_DIR}/fw_apply_invalid_json.err" "${BIN}" --json firewall apply --bogus
assert_json_parseable "${TMP_DIR}/fw_apply_invalid_json.out"
assert_contains "${TMP_DIR}/fw_apply_invalid_json.out" '"result":"usage_error"'

# uninstall safe combinations.
TEST_ROOT="${TMP_DIR}/opt/hardhat"
TEST_BIN_DIR="${TMP_DIR}/usr/local/bin"
mkdir -p "${TEST_ROOT}/bin" "${TEST_BIN_DIR}"
: >"${TEST_ROOT}/bin/hardhat"
ln -s "${TEST_ROOT}/bin/hardhat" "${TEST_BIN_DIR}/hardhat"

assert_exit_code 0 "${TMP_DIR}/uninstall_combo.out" "${TMP_DIR}/uninstall_combo.err" "${BIN}" uninstall --dry-run --yes --purge-config --install-root "${TEST_ROOT}" --bin-dir "${TEST_BIN_DIR}"
assert_contains "${TMP_DIR}/uninstall_combo.out" "Dry-run|dry-run"

assert_exit_code 30 "${TMP_DIR}/uninstall_cancel.out" "${TMP_DIR}/uninstall_cancel.err" sh -c "printf 'n\n' | \"${BIN}\" uninstall --dry-run --install-root \"${TEST_ROOT}\" --bin-dir \"${TEST_BIN_DIR}\""
assert_contains "${TMP_DIR}/uninstall_cancel.out" "cancel|cancelada|cancelled"

assert_exit_code 30 "${TMP_DIR}/uninstall_cancel_json.out" "${TMP_DIR}/uninstall_cancel_json.err" sh -c "printf 'n\n' | \"${BIN}\" --json uninstall --dry-run --install-root \"${TEST_ROOT}\" --bin-dir \"${TEST_BIN_DIR}\""
assert_json_parseable "${TMP_DIR}/uninstall_cancel_json.out"
assert_contains "${TMP_DIR}/uninstall_cancel_json.out" '"result":"aborted"'

assert_exit_code 2 "${TMP_DIR}/uninstall_invalid_json.out" "${TMP_DIR}/uninstall_invalid_json.err" "${BIN}" --json uninstall --bogus
assert_json_parseable "${TMP_DIR}/uninstall_invalid_json.out"
assert_contains "${TMP_DIR}/uninstall_invalid_json.out" '"result":"usage_error"'

echo "[ok] cli edge cases smoke passed"
