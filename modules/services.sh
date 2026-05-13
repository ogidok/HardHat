#!/usr/bin/env bash

HARDHAT_AUDIT_ACTIVE_SERVICES=""

hardhat_module_services_check() {
  hardhat_module_services_collect

  hardhat_log_info "Services audit:"
  hardhat_log_info "- Active relevant services: ${HARDHAT_AUDIT_ACTIVE_SERVICES:-none detected}"
  return 0
}

hardhat_module_services_collect() {
  local -a relevant_services=(sshd ufw docker cups avahi-daemon bluetooth)
  local -a active_services=()
  local service=""

  HARDHAT_AUDIT_ACTIVE_SERVICES=""

  if ! command -v systemctl >/dev/null 2>&1; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "services.systemctl_unavailable" \
        "low" \
        "Unable to inspect active services" \
        "systemctl is not available, so service state could not be checked." \
        "Validate active services manually for your init system."
    fi
    return 0
  fi

  for service in "${relevant_services[@]}"; do
    if systemctl is-active --quiet "${service}" 2>/dev/null; then
      active_services+=("${service}")
    fi
  done

  if ((${#active_services[@]} > 0)); then
    HARDHAT_AUDIT_ACTIVE_SERVICES="$(hardhat_join_by "," "${active_services[@]}")"
  else
    HARDHAT_AUDIT_ACTIVE_SERVICES="none"
  fi

  for service in "${active_services[@]}"; do
    case "${service}" in
      docker)
        if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
          hardhat_audit_add_finding \
            "services.docker_active" \
            "medium" \
            "Docker service is active" \
            "Container services can expand attack surface if not tightly configured." \
            "Review exposed container ports and daemon access controls."
        fi
        ;;
      cups)
        if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
          hardhat_audit_add_finding \
            "services.cups_active" \
            "low" \
            "CUPS printing service is active" \
            "Printer services may expose local or network endpoints." \
            "Disable CUPS if printing is not required."
        fi
        ;;
      avahi-daemon)
        if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
          hardhat_audit_add_finding \
            "services.avahi_active" \
            "low" \
            "Avahi service is active" \
            "mDNS service discovery may expose host details on local networks." \
            "Disable Avahi on systems where service discovery is unnecessary."
        fi
        ;;
      bluetooth)
        if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
          hardhat_audit_add_finding \
            "services.bluetooth_active" \
            "low" \
            "Bluetooth service is active" \
            "Wireless services can increase attack opportunities when unused." \
            "Disable Bluetooth service if not needed."
        fi
        ;;
      sshd)
        if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
          hardhat_audit_add_finding \
            "services.sshd_active" \
            "low" \
            "SSH service is active" \
            "Remote access is enabled through SSH." \
            "Keep SSH hardened and restricted to trusted users and networks."
        fi
        ;;
    esac
  done
}