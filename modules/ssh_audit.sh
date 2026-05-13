#!/usr/bin/env bash

hardhat_module_ssh_audit_read_option() {
  local key="$1"
  local config_files=()
  local file

  if [[ -f /etc/ssh/sshd_config ]]; then
    config_files+=("/etc/ssh/sshd_config")
  fi

  if [[ -d /etc/ssh/sshd_config.d ]]; then
    while IFS= read -r file; do
      config_files+=("${file}")
    done < <(find /etc/ssh/sshd_config.d -maxdepth 1 -type f -name '*.conf' 2>/dev/null | sort)
  fi

  local value=""
  local line
  for file in "${config_files[@]}"; do
    while IFS= read -r line; do
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      if [[ "${line}" =~ ^[[:space:]]*${key}[[:space:]]+(.+)$ ]]; then
        value="${BASH_REMATCH[1]}"
      fi
    done <"${file}"
  done

  printf '%s' "$(hardhat_trim "${value}")"
}

hardhat_module_ssh_audit_collect() {
  if [[ ! -f /etc/ssh/sshd_config ]] && [[ ! -d /etc/ssh/sshd_config.d ]]; then
    hardhat_audit_add_note "SSH configuration not found."
    return 0
  fi

  local password_auth
  local root_login
  local ssh_port

  password_auth="$(hardhat_module_ssh_audit_read_option "PasswordAuthentication")"
  root_login="$(hardhat_module_ssh_audit_read_option "PermitRootLogin")"
  ssh_port="$(hardhat_module_ssh_audit_read_option "Port")"

  if [[ -z "${password_auth}" ]]; then
    hardhat_audit_add_note "SSH PasswordAuthentication not explicitly set."
  elif [[ "${password_auth,,}" == "yes" ]]; then
    hardhat_audit_add_finding \
      "ssh.password_auth.enabled" \
      "medium" \
      "SSH password authentication enabled" \
      "PasswordAuthentication is set to yes, increasing brute-force exposure." \
      "Prefer key-based authentication and set PasswordAuthentication no when possible."
  else
    hardhat_audit_add_note "SSH PasswordAuthentication appears restricted (${password_auth})."
  fi

  if [[ -z "${root_login}" ]]; then
    hardhat_audit_add_note "SSH PermitRootLogin not explicitly set."
  elif [[ "${root_login,,}" == "yes" ]]; then
    hardhat_audit_add_finding \
      "ssh.root_login.enabled" \
      "high" \
      "SSH root login enabled" \
      "PermitRootLogin is set to yes, allowing direct remote root authentication." \
      "Set PermitRootLogin no (or at minimum prohibit-password) and use sudo for elevation."
  else
    hardhat_audit_add_note "SSH PermitRootLogin appears restricted (${root_login})."
  fi

  if [[ -n "${ssh_port}" ]]; then
    hardhat_audit_add_note "SSH configured port: ${ssh_port}."
  fi
}

hardhat_module_ssh_audit_check() {
  hardhat_module_ssh_audit_collect
  return 0
}