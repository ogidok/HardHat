#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/common.sh"
# shellcheck disable=SC1091
source "${ROOT_DIR}/lib/validate.sh"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  if [[ "${expected}" != "${actual}" ]]; then
    echo "[fail] ${msg}" >&2
    echo "[fail] expected='${expected}' actual='${actual}'" >&2
    exit 1
  fi
}

assert_true() {
  local msg="$1"
  shift
  if ! "$@"; then
    echo "[fail] ${msg}" >&2
    exit 1
  fi
}

assert_false() {
  local msg="$1"
  shift
  if "$@"; then
    echo "[fail] ${msg}" >&2
    exit 1
  fi
}

echo "[unit] helpers"

assert_eq "hola" "$(hardhat_trim '  hola  ')" "hardhat_trim removes surrounding spaces"
assert_eq "a,b,c" "$(hardhat_join_by ',' a b c)" "hardhat_join_by joins with delimiter"
assert_eq "" "$(hardhat_join_by ',')" "hardhat_join_by handles empty input"

assert_true "hardhat_validate_non_empty accepts non-empty" hardhat_validate_non_empty " value "
assert_false "hardhat_validate_non_empty rejects blanks" hardhat_validate_non_empty "   "

assert_true "hardhat_validate_choice accepts listed option" hardhat_validate_choice "es" "en" "es"
assert_false "hardhat_validate_choice rejects missing option" hardhat_validate_choice "fr" "en" "es"

assert_true "hardhat_validate_boolean_like accepts yes" hardhat_validate_boolean_like "yes"
assert_true "hardhat_validate_boolean_like accepts false" hardhat_validate_boolean_like "false"
assert_false "hardhat_validate_boolean_like rejects maybe" hardhat_validate_boolean_like "maybe"

assert_true "hardhat_validate_language_code accepts en" hardhat_validate_language_code "en"
assert_true "hardhat_validate_language_code accepts es" hardhat_validate_language_code "es"
assert_false "hardhat_validate_language_code rejects fr" hardhat_validate_language_code "fr"

echo "[ok] unit helpers passed"
