#!/usr/bin/env bash

HARDHAT_LANG="en"
HARDHAT_GLOBAL_CONFIG_FILE="/etc/hardhat/config"
HARDHAT_USER_CONFIG_FILE="${HOME}/.config/hardhat/config"

hardhat_language_load_from_file() {
  local file="$1"
  [[ -f "${file}" ]] || return 1

  local line key value
  while IFS='=' read -r key value; do
    [[ "${key}" =~ ^[[:space:]]*# ]] && continue
    if [[ "$(hardhat_trim "${key}")" == "HARDHAT_LANG" ]]; then
      value="$(hardhat_trim "${value}")"
      value="${value%\"}"
      value="${value#\"}"
      if hardhat_validate_language_code "${value}"; then
        HARDHAT_LANG="${value}"
      fi
    fi
  done <"${file}"
}

hardhat_language_load() {
  HARDHAT_LANG="en"
  hardhat_language_load_from_file "${HARDHAT_GLOBAL_CONFIG_FILE}" || true
  hardhat_language_load_from_file "${HARDHAT_USER_CONFIG_FILE}" || true
}

hardhat_language_set_user() {
  local lang="$1"
  if ! hardhat_validate_language_code "${lang}"; then
    return 1
  fi

  local dir
  dir="$(dirname "${HARDHAT_USER_CONFIG_FILE}")"
  mkdir -p "${dir}" || return 1
  printf 'HARDHAT_LANG=%s\n' "${lang}" >"${HARDHAT_USER_CONFIG_FILE}" || return 1
  return 0
}
