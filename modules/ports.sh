#!/usr/bin/env bash

hardhat_module_ports_collect_audit() {
  local raw
  local -a lines=()

  if command -v ss >/dev/null 2>&1; then
    raw="$(ss -lntuH 2>/dev/null || true)"
  elif command -v netstat >/dev/null 2>&1; then
    raw="$(netstat -lntu 2>/dev/null | tail -n +3 || true)"
  else
    hardhat_audit_add_note "Port checks skipped: ss/netstat unavailable."
    hardhat_audit_add_finding \
      "ports.check.unavailable" \
      "low" \
      "Port check unavailable" \
      "No supported tool found to inspect listening ports." \
      "Install iproute2 for ss command availability."
    return 0
  fi

  if [[ -z "${raw}" ]]; then
    hardhat_audit_add_note "No listening TCP/UDP ports detected by current user context."
    return 0
  fi

  while IFS= read -r line; do
    [[ -n "${line}" ]] && lines+=("${line}")
  done <<<"${raw}"

  hardhat_audit_add_note "Listening port entries detected: ${#lines[@]}."

  local exposed_count
  exposed_count="$(printf '%s\n' "${lines[@]}" | grep -Ec '(^|[[:space:]])(0\.0\.0\.0|\*|\[::\]|::):' || true)"
  if [[ -n "${exposed_count}" ]] && ((exposed_count > 0)); then
    hardhat_audit_add_finding \
      "ports.listen.exposed" \
      "medium" \
      "Public listening sockets detected" \
      "Some services are listening on wildcard or public interfaces." \
      "Limit unnecessary bind addresses and restrict incoming access with firewall rules."
  fi

  if printf '%s\n' "${lines[@]}" | grep -Eq '(:23[[:space:]]|:23$|\*:23[[:space:]])'; then
    hardhat_audit_add_finding \
      "ports.telnet.open" \
      "high" \
      "Telnet port appears open" \
      "Port 23 is listening, which usually indicates insecure plaintext remote access." \
      "Disable Telnet services and use SSH with hardened configuration."
  fi

  if printf '%s\n' "${lines[@]}" | grep -Eq '(:3389[[:space:]]|:3389$|\*:3389[[:space:]])'; then
    hardhat_audit_add_finding \
      "ports.rdp.open" \
      "medium" \
      "RDP port appears open" \
      "Port 3389 is listening and may increase remote attack surface if exposed." \
      "Restrict RDP access to trusted networks and enforce firewall controls."
  fi
}

hardhat_module_ports_check() {
  hardhat_module_ports_collect_audit
  return 0
}