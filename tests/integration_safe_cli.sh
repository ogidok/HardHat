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

assert_json_like() {
  local file="$1"
  assert_contains "${file}" '^\{'
  assert_contains "${file}" '"metadata"'
  assert_contains "${file}" '"summary"'
}

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "arch" ]] && [[ "${ID_LIKE:-}" != *"arch"* ]]; then
    echo "[skip] integration safe CLI tests are scoped to Arch-based environments"
    exit 0
  fi
fi

echo "[integration] safe cli (dry-run + json)"

assert_success firewall_apply_dry_run "${BIN}" firewall apply --dry-run --yes
assert_contains "${TMP_DIR}/firewall_apply_dry_run.out" 'Dry-run|dry-run|Simula|simula'

assert_success audit_json "${BIN}" audit --json
assert_json_like "${TMP_DIR}/audit_json.out"
assert_contains "${TMP_DIR}/audit_json.out" '"findings"'

assert_success firewall_audit_json "${BIN}" firewall audit --json
assert_json_like "${TMP_DIR}/firewall_audit_json.out"
assert_contains "${TMP_DIR}/firewall_audit_json.out" '"firewall"'

assert_success firewall_apply_json_dry_run "${BIN}" --json firewall apply --dry-run --yes
assert_json_like "${TMP_DIR}/firewall_apply_json_dry_run.out"
assert_contains "${TMP_DIR}/firewall_apply_json_dry_run.out" '"apply"'

echo "[ok] integration safe cli passed"
