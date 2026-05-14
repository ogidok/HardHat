#!/usr/bin/env bash

hardhat_updates_capture_with_timeout() {
  local timeout_seconds="${1}"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "${timeout_seconds}" "$@" 2>/dev/null
    return $?
  fi

  "$@" 2>/dev/null
}

hardhat_module_updates_collect_audit() {
  local updates_raw=""
  local updates_count=0
  local updates_rc=0

  if command -v checkupdates >/dev/null 2>&1; then
    if ! updates_raw="$(hardhat_updates_capture_with_timeout 15s checkupdates)"; then
      updates_rc=$?
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if ! updates_raw="$(hardhat_updates_capture_with_timeout 15s pacman -Qu)"; then
      updates_rc=$?
    fi
  else
    hardhat_audit_add_note "Update check skipped: pacman/checkupdates unavailable."
    hardhat_audit_add_finding \
      "updates.check.unavailable" \
      "low" \
      "Update check unavailable" \
      "HardHat could not find pacman or checkupdates to inspect pending updates." \
      "Install pacman tooling and run update checks regularly."
    return 0
  fi

  if [[ "${updates_rc}" -eq 124 ]]; then
    hardhat_audit_add_note "Update check timed out after 15s."
    hardhat_audit_add_finding \
      "updates.check.timeout" \
      "low" \
      "Update check timed out" \
      "HardHat stopped update check after timeout to avoid blocking audit execution." \
      "Run checkupdates or pacman -Qu manually to verify pending updates."
    return 0
  fi

  if [[ -n "${updates_raw}" ]]; then
    updates_count="$(grep -c '.' <<<"${updates_raw}" || true)"
  fi

  hardhat_audit_add_note "Pending package updates detected: ${updates_count}."

  if ((updates_count >= 50)); then
    hardhat_audit_add_finding \
      "updates.pending.high" \
      "high" \
      "Many pending system updates" \
      "A large number of pending package updates may include unresolved security fixes." \
      "Review and apply system updates as soon as possible."
  elif ((updates_count >= 10)); then
    hardhat_audit_add_finding \
      "updates.pending.medium" \
      "medium" \
      "Pending system updates" \
      "Several package updates are pending and may include security patches." \
      "Apply pending updates in a controlled maintenance window."
  elif ((updates_count > 0)); then
    hardhat_audit_add_finding \
      "updates.pending.low" \
      "low" \
      "Few pending updates" \
      "Some updates are pending and keeping packages current reduces exposure." \
      "Apply pending updates soon."
  fi
}

hardhat_module_updates_check() {
  hardhat_module_updates_collect_audit
  return 0
}