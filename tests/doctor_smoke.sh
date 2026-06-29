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

assert_exit_in_set() {
  local out_file="$1"
  local err_file="$2"
  shift 2

  local rc=0
  "$@" >"${out_file}" 2>"${err_file}" || rc=$?

  if [[ "${rc}" -ne 0 ]] && [[ "${rc}" -ne 10 ]]; then
    echo "[fail] Expected exit code 0 or 10, got ${rc}: $*" >&2
    echo "[fail] stdout:" >&2
    cat "${out_file}" >&2 || true
    echo "[fail] stderr:" >&2
    cat "${err_file}" >&2 || true
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

echo "[smoke] doctor command"

assert_exit_in_set "${TMP_DIR}/doctor.out" "${TMP_DIR}/doctor.err" "${BIN}" doctor
assert_contains "${TMP_DIR}/doctor.out" "Doctor"
assert_contains "${TMP_DIR}/doctor.out" "Checks"

assert_exit_code 0 "${TMP_DIR}/doctor_help.out" "${TMP_DIR}/doctor_help.err" "${BIN}" doctor --help
assert_contains "${TMP_DIR}/doctor_help.out" "hardhat doctor"

assert_exit_in_set "${TMP_DIR}/doctor_json.out" "${TMP_DIR}/doctor_json.err" "${BIN}" --json doctor
assert_json_parseable "${TMP_DIR}/doctor_json.out"
assert_contains "${TMP_DIR}/doctor_json.out" '"command":"doctor"'
assert_contains "${TMP_DIR}/doctor_json.out" '"status"'
assert_contains "${TMP_DIR}/doctor_json.out" '"summary"'
assert_contains "${TMP_DIR}/doctor_json.out" '"checks"'
assert_contains "${TMP_DIR}/doctor_json.out" '"notes"'
assert_contains "${TMP_DIR}/doctor_json.out" '"recommendations"'
assert_not_contains "${TMP_DIR}/doctor_json.out" '\[INFO\]|\[WARN\]|\[ERROR\]'

assert_exit_code 2 "${TMP_DIR}/doctor_invalid_json.out" "${TMP_DIR}/doctor_invalid_json.err" "${BIN}" --json doctor --bogus
assert_json_parseable "${TMP_DIR}/doctor_invalid_json.out"
assert_contains "${TMP_DIR}/doctor_invalid_json.out" '"result":"usage_error"'

echo "[ok] doctor smoke passed"
