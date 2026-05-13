#!/usr/bin/env bash

HARDHAT_AUDIT_PORTS_TOOL="none"
HARDHAT_AUDIT_LISTENING_SOCKET_COUNT=0
HARDHAT_AUDIT_LISTENING_PORTS=""

hardhat_module_ports_check() {
  hardhat_module_ports_collect

  hardhat_log_info "Ports audit:"
  hardhat_log_info "- Tool: ${HARDHAT_AUDIT_PORTS_TOOL}"
  hardhat_log_info "- Listening sockets: ${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT}"
  hardhat_log_info "- Listening ports: ${HARDHAT_AUDIT_LISTENING_PORTS:-none detected}"
  return 0
}

hardhat_module_ports_collect() {
  local -a endpoints=()
  local -a unique_ports=()
  local endpoint=""
  local port=""
  local risky_port=""
  local risky_count=0
  local unique_ports_csv=""

  HARDHAT_AUDIT_PORTS_TOOL="none"
  HARDHAT_AUDIT_LISTENING_SOCKET_COUNT=0
  HARDHAT_AUDIT_LISTENING_PORTS=""

  if command -v ss >/dev/null 2>&1; then
    HARDHAT_AUDIT_PORTS_TOOL="ss"
    mapfile -t endpoints < <(ss -tulnH 2>/dev/null | awk '{print $5}')
  elif command -v netstat >/dev/null 2>&1; then
    HARDHAT_AUDIT_PORTS_TOOL="netstat"
    mapfile -t endpoints < <(netstat -tuln 2>/dev/null | awk 'NR>2 {print $4}')
  else
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ports.check_unavailable" \
        "low" \
        "Unable to inspect listening ports" \
        "Neither ss nor netstat was found in PATH." \
        "Install iproute2 or net-tools to enable port visibility."
    fi
    return 0
  fi

  HARDHAT_AUDIT_LISTENING_SOCKET_COUNT="${#endpoints[@]}"

  if ((${#endpoints[@]} == 0)); then
    HARDHAT_AUDIT_LISTENING_PORTS="none"
    return 0
  fi

  declare -A seen_ports=()
  for endpoint in "${endpoints[@]}"; do
    port="${endpoint##*:}"
    port="${port//]/}"
    port="${port//[/}"
    if [[ "${port}" =~ ^[0-9]+$ ]]; then
      seen_ports["${port}"]=1
    fi
  done

  if ((${#seen_ports[@]} > 0)); then
    mapfile -t unique_ports < <(printf '%s\n' "${!seen_ports[@]}" | sort -n)
    unique_ports_csv="$(hardhat_join_by "," "${unique_ports[@]}")"
    HARDHAT_AUDIT_LISTENING_PORTS="${unique_ports_csv}"
  else
    HARDHAT_AUDIT_LISTENING_PORTS="unavailable"
  fi

  if [[ "${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT}" -gt 20 ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ports.many_listeners" \
        "medium" \
        "High number of listening sockets" \
        "Detected ${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT} listening sockets." \
        "Review exposed services and keep only required listeners."
    fi
  elif [[ "${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT}" -gt 0 ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ports.listeners_present" \
        "low" \
        "Open listening sockets detected" \
        "Detected ${HARDHAT_AUDIT_LISTENING_SOCKET_COUNT} listening sockets on this host." \
        "Validate each exposed port and close what is unnecessary."
    fi
  fi

  for risky_port in 21 23 25 53 80 110 139 143 445 3306 5432 6379 27017; do
    if [[ -n "${seen_ports[${risky_port}]:-}" ]]; then
      risky_count=$((risky_count + 1))
      if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
        hardhat_audit_add_finding \
          "ports.risky_${risky_port}" \
          "medium" \
          "Potentially sensitive port ${risky_port} is listening" \
          "A commonly targeted or sensitive service appears exposed on port ${risky_port}." \
          "Restrict exposure with firewall rules and confirm service necessity."
      fi
    fi
  done

  hardhat_log_debug "Detected ${risky_count} potentially sensitive listening ports."
}