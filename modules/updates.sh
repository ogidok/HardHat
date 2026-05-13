#!/usr/bin/env bash

hardhat_module_updates_collect_audit() {
  local updates_raw=""
  local updates_count=0

  if command -v checkupdates >/dev/null 2>&1; then
    updates_raw="$(checkupdates 2>/dev/null || true)"
  elif command -v pacman >/dev/null 2>&1; then
    updates_raw="$(pacman -Qu 2>/dev/null || true)"
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