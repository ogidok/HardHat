#!/usr/bin/env bash

hardhat_updates_capture_with_timeout() {
  local timeout_seconds="${1}"
  shift

  if command -v timeout >/dev/null 2>&1; then
    timeout "${timeout_seconds}" "$@" 2>/dev/null
    return $?
  fi

  "$@" 2>/dev/null
}

hardhat_module_updates_collect_audit() {
  local updates_raw=""
  local updates_count=0
  local updates_rc=0
  local use_es=0

  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    use_es=1
  fi

  if command -v checkupdates >/dev/null 2>&1; then
    if ! updates_raw="$(hardhat_updates_capture_with_timeout 15s checkupdates)"; then
      updates_rc=$?
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if ! updates_raw="$(hardhat_updates_capture_with_timeout 15s pacman -Qu)"; then
      updates_rc=$?
    fi
  else
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Check de updates omitido: pacman/checkupdates no disponible."
      hardhat_audit_add_finding \
        "updates.check.unavailable" \
        "low" \
        "Check de updates no disponible" \
        "HardHat no pudo encontrar pacman o checkupdates para inspeccionar updates pendientes." \
        "Instala herramientas de pacman y ejecuta checks de updates regularmente."
    else
      hardhat_audit_add_note "Update check skipped: pacman/checkupdates unavailable."
      hardhat_audit_add_finding \
        "updates.check.unavailable" \
        "low" \
        "Update check unavailable" \
        "HardHat could not find pacman or checkupdates to inspect pending updates." \
        "Install pacman tooling and run update checks regularly."
    fi
    return 0
  fi

  if [[ "${updates_rc}" -eq 124 ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Check de updates agotado despues de 15s."
      hardhat_audit_add_finding \
        "updates.check.timeout" \
        "low" \
        "Check de updates agotado" \
        "HardHat detuvo el check de updates por timeout para evitar bloquear la auditoria." \
        "Ejecuta checkupdates o pacman -Qu manualmente para verificar updates pendientes."
    else
      hardhat_audit_add_note "Update check timed out after 15s."
      hardhat_audit_add_finding \
        "updates.check.timeout" \
        "low" \
        "Update check timed out" \
        "HardHat stopped update check after timeout to avoid blocking audit execution." \
        "Run checkupdates or pacman -Qu manually to verify pending updates."
    fi
    return 0
  fi

  if [[ -n "${updates_raw}" ]]; then
    updates_count="$(grep -c '.' <<<"${updates_raw}" || true)"
  fi

  if [[ "${use_es}" -eq 1 ]]; then
    hardhat_audit_add_note "Updates de paquetes pendientes detectados: ${updates_count}."
  else
    hardhat_audit_add_note "Pending package updates detected: ${updates_count}."
  fi

  if ((updates_count >= 50)); then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "updates.pending.high" \
        "high" \
        "Muchos updates de sistema pendientes" \
        "Un numero alto de updates pendientes puede incluir fixes de seguridad sin aplicar." \
        "Revisa y aplica updates del sistema lo antes posible."
    else
      hardhat_audit_add_finding \
        "updates.pending.high" \
        "high" \
        "Many pending system updates" \
        "A large number of pending package updates may include unresolved security fixes." \
        "Review and apply system updates as soon as possible."
    fi
  elif ((updates_count >= 10)); then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "updates.pending.medium" \
        "medium" \
        "Updates de sistema pendientes" \
        "Varios updates de paquetes estan pendientes y pueden incluir parches de seguridad." \
        "Aplica updates pendientes en una ventana de mantenimiento controlada."
    else
      hardhat_audit_add_finding \
        "updates.pending.medium" \
        "medium" \
        "Pending system updates" \
        "Several package updates are pending and may include security patches." \
        "Apply pending updates in a controlled maintenance window."
    fi
  elif ((updates_count > 0)); then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "updates.pending.low" \
        "low" \
        "Pocos updates pendientes" \
        "Hay updates pendientes y mantener paquetes al dia reduce exposicion." \
        "Aplica updates pendientes pronto."
    else
      hardhat_audit_add_finding \
        "updates.pending.low" \
        "low" \
        "Few pending updates" \
        "Some updates are pending and keeping packages current reduces exposure." \
        "Apply pending updates soon."
    fi
  fi
}

hardhat_module_updates_check() {
  hardhat_module_updates_collect_audit
  return 0
}