#!/usr/bin/env bash

hardhat_module_services_collect_audit() {
  local use_es=0
  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    use_es=1
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Check de servicios omitido: systemctl no disponible."
      hardhat_audit_add_finding \
        "services.check.unavailable" \
        "low" \
        "Check de servicios no disponible" \
        "systemctl no esta disponible, por lo que no se pudieron auditar servicios en ejecucion." \
        "Ejecuta la auditoria en un entorno basado en systemd para inspeccionar servicios activos."
    else
      hardhat_audit_add_note "Service checks skipped: systemctl unavailable."
      hardhat_audit_add_finding \
        "services.check.unavailable" \
        "low" \
        "Service check unavailable" \
        "systemctl is not available, so running services could not be audited." \
        "Run audit on a systemd-based environment to inspect running services."
    fi
    return 0
  fi

  local running
  running="$(systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null || true)"
  if [[ -z "${running}" ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "No se detectaron servicios en ejecucion o la salida no esta disponible."
    else
      hardhat_audit_add_note "No running services detected or output unavailable."
    fi
    return 0
  fi

  local running_count
  running_count="$(wc -l <<<"${running}" | tr -d ' ')"
  if [[ "${use_es}" -eq 1 ]]; then
    hardhat_audit_add_note "Servicios en ejecucion detectados: ${running_count}."
  else
    hardhat_audit_add_note "Running services detected: ${running_count}."
  fi

  local risky_service
  for risky_service in avahi-daemon cups docker libvirtd rpcbind nfs-server smb; do
    if grep -q "${risky_service}\.service" <<<"${running}"; then
      if [[ "${use_es}" -eq 1 ]]; then
        hardhat_audit_add_finding \
          "services.${risky_service}.running" \
          "low" \
          "Servicio potencialmente expuesto en ejecucion: ${risky_service}" \
          "El servicio ${risky_service} esta activo y puede exponer superficie de ataque de red adicional." \
          "Deshabilita o restringe ${risky_service} si no es necesario en este host."
      else
        hardhat_audit_add_finding \
          "services.${risky_service}.running" \
          "low" \
          "Potentially exposed service running: ${risky_service}" \
          "Service ${risky_service} is active and may expose additional network attack surface." \
          "Disable or restrict ${risky_service} if it is not required on this host."
      fi
    fi
  done

  if grep -q 'sshd\.service' <<<"${running}"; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "El servicio sshd esta en ejecucion."
    else
      hardhat_audit_add_note "sshd service is running."
    fi
  else
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "El servicio sshd no esta en ejecucion."
    else
      hardhat_audit_add_note "sshd service is not running."
    fi
  fi
}

hardhat_module_services_check() {
  hardhat_module_services_collect_audit
  return 0
}