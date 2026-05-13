#!/usr/bin/env bash

HARDHAT_AUDIT_UPDATES_SOURCE="unknown"
HARDHAT_AUDIT_PENDING_UPDATES=0

hardhat_module_updates_check() {
  hardhat_module_updates_collect

  hardhat_log_info "Updates audit:"
  hardhat_log_info "- Source: ${HARDHAT_AUDIT_UPDATES_SOURCE}"
  hardhat_log_info "- Pending updates: ${HARDHAT_AUDIT_PENDING_UPDATES}"
  return 0
}

hardhat_module_updates_collect() {
  local output=""
  local count=0

  HARDHAT_AUDIT_UPDATES_SOURCE="unknown"
  HARDHAT_AUDIT_PENDING_UPDATES=0

  if command -v checkupdates >/dev/null 2>&1; then
    HARDHAT_AUDIT_UPDATES_SOURCE="checkupdates"
    output="$(checkupdates 2>/dev/null || true)"
  elif command -v pacman >/dev/null 2>&1; then
    HARDHAT_AUDIT_UPDATES_SOURCE="pacman -Qu"
    output="$(pacman -Qu 2>/dev/null || true)"
  else
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "updates.check_unavailable" \
        "low" \
        "Unable to check pending updates" \
        "Neither checkupdates nor pacman command is available." \
        "Ensure package manager tooling is installed and accessible."
    fi
    return 0
  fi

  if hardhat_validate_non_empty "${output}"; then
    count="$(printf '%s\n' "${output}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  else
    count=0
  fi

  HARDHAT_AUDIT_PENDING_UPDATES="${count}"

  if [[ "${count}" -gt 100 ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "updates.pending_many" \
        "high" \
        "Many pending system updates" \
        "Detected ${count} pending updates." \
        "Update packages soon to reduce exposure to known vulnerabilities."
    fi
  elif [[ "${count}" -gt 30 ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "updates.pending_moderate" \
        "medium" \
        "Moderate number of pending updates" \
        "Detected ${count} pending updates." \
        "Schedule a package update window in the near term."
    fi
  elif [[ "${count}" -gt 0 ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "updates.pending_few" \
        "low" \
        "Pending package updates detected" \
        "Detected ${count} pending updates." \
        "Keep the system updated regularly to reduce risk."
    fi
  fi
}