#!/usr/bin/env bash

hardhat_module_services_collect_audit() {
  if ! command -v systemctl >/dev/null 2>&1; then
    hardhat_audit_add_note "Service checks skipped: systemctl unavailable."
    hardhat_audit_add_finding \
      "services.check.unavailable" \
      "low" \
      "Service check unavailable" \
      "systemctl is not available, so running services could not be audited." \
      "Run audit on a systemd-based environment to inspect running services."
    return 0
  fi

  local running
  running="$(systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null || true)"
  if [[ -z "${running}" ]]; then
    hardhat_audit_add_note "No running services detected or output unavailable."
    return 0
  fi

  local running_count
  running_count="$(wc -l <<<"${running}" | tr -d ' ')"
  hardhat_audit_add_note "Running services detected: ${running_count}."

  local risky_service
  for risky_service in avahi-daemon cups docker libvirtd rpcbind nfs-server smb; do
    if grep -q "${risky_service}\.service" <<<"${running}"; then
      hardhat_audit_add_finding \
        "services.${risky_service}.running" \
        "low" \
        "Potentially exposed service running: ${risky_service}" \
        "Service ${risky_service} is active and may expose additional network attack surface." \
        "Disable or restrict ${risky_service} if it is not required on this host."
    fi
  done

  if grep -q 'sshd\.service' <<<"${running}"; then
    hardhat_audit_add_note "sshd service is running."
  else
    hardhat_audit_add_note "sshd service is not running."
  fi
}

hardhat_module_services_check() {
  hardhat_module_services_collect_audit
  return 0
}