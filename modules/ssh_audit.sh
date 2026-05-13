#!/usr/bin/env bash

HARDHAT_AUDIT_SSH_SERVICE_ACTIVE="unknown"
HARDHAT_AUDIT_SSH_PASSWORD_AUTH="unknown"
HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN="unknown"
HARDHAT_AUDIT_SSH_PORT="unknown"

hardhat_module_ssh_audit_setting_from_effective() {
  local key="$1"
  local effective="$2"
  printf '%s\n' "${effective}" | awk -v k="${key}" '$1 == k {print tolower($2); exit}'
}

hardhat_module_ssh_audit_setting_from_file() {
  local key="$1"
  local config_file="$2"
  grep -Ei "^[[:space:]]*${key}[[:space:]]+" "${config_file}" 2>/dev/null | tail -n 1 | awk '{print tolower($2)}'
}

hardhat_module_ssh_audit_check() {
  hardhat_module_ssh_audit_collect

  hardhat_log_info "SSH audit:"
  hardhat_log_info "- sshd active: ${HARDHAT_AUDIT_SSH_SERVICE_ACTIVE}"
  hardhat_log_info "- PasswordAuthentication: ${HARDHAT_AUDIT_SSH_PASSWORD_AUTH}"
  hardhat_log_info "- PermitRootLogin: ${HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN}"
  hardhat_log_info "- Port: ${HARDHAT_AUDIT_SSH_PORT}"
  return 0
}

hardhat_module_ssh_audit_collect() {
  local sshd_config="/etc/ssh/sshd_config"
  local effective_config=""
  local password_auth=""
  local permit_root_login=""
  local ssh_port=""

  HARDHAT_AUDIT_SSH_SERVICE_ACTIVE="unknown"
  HARDHAT_AUDIT_SSH_PASSWORD_AUTH="unknown"
  HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN="unknown"
  HARDHAT_AUDIT_SSH_PORT="unknown"

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet sshd 2>/dev/null; then
      HARDHAT_AUDIT_SSH_SERVICE_ACTIVE="active"
    else
      HARDHAT_AUDIT_SSH_SERVICE_ACTIVE="inactive"
    fi
  fi

  if command -v sshd >/dev/null 2>&1; then
    effective_config="$(sshd -T 2>/dev/null || true)"
  fi

  if hardhat_validate_non_empty "${effective_config}"; then
    password_auth="$(hardhat_module_ssh_audit_setting_from_effective passwordauthentication "${effective_config}")"
    permit_root_login="$(hardhat_module_ssh_audit_setting_from_effective permitrootlogin "${effective_config}")"
    ssh_port="$(hardhat_module_ssh_audit_setting_from_effective port "${effective_config}")"
  elif [[ -f "${sshd_config}" ]]; then
    password_auth="$(hardhat_module_ssh_audit_setting_from_file PasswordAuthentication "${sshd_config}")"
    permit_root_login="$(hardhat_module_ssh_audit_setting_from_file PermitRootLogin "${sshd_config}")"
    ssh_port="$(hardhat_module_ssh_audit_setting_from_file Port "${sshd_config}")"
  else
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ssh.config_unavailable" \
        "low" \
        "Unable to inspect SSH configuration" \
        "Neither effective SSH settings nor sshd_config file could be read." \
        "Verify SSH configuration manually if SSH is expected on this host."
    fi
    return 0
  fi

  if hardhat_validate_non_empty "${password_auth}"; then
    HARDHAT_AUDIT_SSH_PASSWORD_AUTH="${password_auth}"
  fi
  if hardhat_validate_non_empty "${permit_root_login}"; then
    HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN="${permit_root_login}"
  fi
  if hardhat_validate_non_empty "${ssh_port}"; then
    HARDHAT_AUDIT_SSH_PORT="${ssh_port}"
  fi

  if [[ "${HARDHAT_AUDIT_SSH_PASSWORD_AUTH}" == "yes" ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ssh.password_auth_enabled" \
        "high" \
        "SSH password authentication is enabled" \
        "PasswordAuthentication is set to yes, increasing brute-force risk." \
        "Use key-based authentication and disable PasswordAuthentication where possible."
    fi
  elif [[ "${HARDHAT_AUDIT_SSH_PASSWORD_AUTH}" == "unknown" ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ssh.password_auth_unknown" \
        "low" \
        "Could not determine SSH password authentication setting" \
        "PasswordAuthentication value could not be parsed." \
        "Review sshd configuration manually to confirm authentication mode."
    fi
  fi

  case "${HARDHAT_AUDIT_SSH_PERMIT_ROOT_LOGIN}" in
    yes)
      if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
        hardhat_audit_add_finding \
          "ssh.root_login_enabled" \
          "high" \
          "SSH root login is enabled" \
          "PermitRootLogin is set to yes." \
          "Disable direct root SSH login and use sudo from named accounts."
      fi
      ;;
    prohibit-password|without-password)
      if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
        hardhat_audit_add_finding \
          "ssh.root_login_limited" \
          "medium" \
          "SSH root login is partially allowed" \
          "PermitRootLogin is not fully disabled." \
          "Set PermitRootLogin to no unless there is a strict operational need."
      fi
      ;;
    unknown)
      if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
        hardhat_audit_add_finding \
          "ssh.root_login_unknown" \
          "low" \
          "Could not determine SSH root login setting" \
          "PermitRootLogin value could not be parsed." \
          "Review sshd configuration manually for root access policy."
      fi
      ;;
  esac

  if [[ "${HARDHAT_AUDIT_SSH_PORT}" == "22" ]]; then
    if declare -F hardhat_audit_add_finding >/dev/null 2>&1; then
      hardhat_audit_add_finding \
        "ssh.default_port" \
        "low" \
        "SSH uses default port 22" \
        "Using the default port is common and easily discoverable." \
        "Consider changing SSH port as an additional noise-reduction measure."
    fi
  fi
}