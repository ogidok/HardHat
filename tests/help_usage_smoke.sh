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

assert_failure() {
  local name="$1"
  shift
  local out_file="${TMP_DIR}/${name}.out"
  if "$@" >"${out_file}" 2>&1; then
    echo "[fail] Command should fail: $*" >&2
    cat "${out_file}" >&2
    exit 1
  fi
}

echo "[smoke] help and usage"

assert_success global_help "${BIN}" help
assert_contains "${TMP_DIR}/global_help.out" "Comandos:|Commands:"

assert_success global_help_short "${BIN}" -h
assert_contains "${TMP_DIR}/global_help_short.out" "HardHat"

assert_success help_firewall_apply "${BIN}" help firewall apply
assert_contains "${TMP_DIR}/help_firewall_apply.out" "firewall apply|Baseline apply|Aplicacion de baseline"

assert_success audit_help "${BIN}" audit --help
assert_contains "${TMP_DIR}/audit_help.out" "hardhat audit"

assert_success firewall_help "${BIN}" firewall --help
assert_contains "${TMP_DIR}/firewall_help.out" "hardhat firewall"

assert_success firewall_audit_help "${BIN}" firewall audit --help
assert_contains "${TMP_DIR}/firewall_audit_help.out" "hardhat firewall audit"

assert_success firewall_apply_help "${BIN}" firewall apply --help
assert_contains "${TMP_DIR}/firewall_apply_help.out" "hardhat firewall apply"

assert_success uninstall_help "${BIN}" uninstall --help
assert_contains "${TMP_DIR}/uninstall_help.out" "hardhat uninstall"

assert_success language_help "${BIN}" language --help
assert_contains "${TMP_DIR}/language_help.out" "hardhat language"

assert_failure invalid_command "${BIN}" no-such-command
assert_contains "${TMP_DIR}/invalid_command.out" "Unknown command|Comando desconocido"
assert_contains "${TMP_DIR}/invalid_command.out" "hardhat help"

assert_failure invalid_audit_arg "${BIN}" audit --bogus
assert_contains "${TMP_DIR}/invalid_audit_arg.out" "audit --help|for usage|para ver uso"

assert_failure invalid_firewall_apply_arg "${BIN}" firewall apply --bogus
assert_contains "${TMP_DIR}/invalid_firewall_apply_arg.out" "firewall apply --help|for usage|para ver uso"

echo "[ok] help and usage smoke passed"
