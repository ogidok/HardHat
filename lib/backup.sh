#!/usr/bin/env bash

hardhat_backup_file() {
  local source_file="$1"
  local backup_dir="${2:-/var/backups/hardhat}"

  if [[ ! -f "${source_file}" ]]; then
    hardhat_log_error "Cannot back up missing file: ${source_file}"
    return 1
  fi

  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  local target="${backup_dir}/$(basename "${source_file}").${ts}.bak"

  hardhat_sudo_run mkdir -p "${backup_dir}" || return 1
  hardhat_sudo_run cp -a "${source_file}" "${target}" || return 1
  hardhat_log_success "Backup created: ${target}"
}