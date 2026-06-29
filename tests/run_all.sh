#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  bash tests/run_all.sh [all|smoke|integration|unit]

Defaults to 'all'.
EOF
}

run_scripts() {
  local label="$1"
  shift
  local script

  echo "[suite] ${label}"
  for script in "$@"; do
    echo "[run] ${script}"
    bash "${ROOT_DIR}/${script}"
  done
}

SMOKE_TESTS=(
  "tests/help_usage_smoke.sh"
  "tests/smoke_core_commands.sh"
  "tests/uninstall_subcommand_smoke.sh"
)

INTEGRATION_TESTS=(
  "tests/integration_safe_cli.sh"
)

UNIT_TESTS=(
  "tests/unit_helpers.sh"
)

MODE="${1:-all}"

case "${MODE}" in
  all)
    run_scripts "smoke" "${SMOKE_TESTS[@]}"
    run_scripts "integration" "${INTEGRATION_TESTS[@]}"
    run_scripts "unit" "${UNIT_TESTS[@]}"
    ;;
  smoke)
    run_scripts "smoke" "${SMOKE_TESTS[@]}"
    ;;
  integration)
    run_scripts "integration" "${INTEGRATION_TESTS[@]}"
    ;;
  unit)
    run_scripts "unit" "${UNIT_TESTS[@]}"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "[fail] Unknown mode: ${MODE}" >&2
    usage >&2
    exit 1
    ;;
esac

echo "[ok] test run completed"
