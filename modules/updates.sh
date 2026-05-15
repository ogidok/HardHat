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
  local updates_source=""
  local updates_confident=0
  local use_es=0

  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    use_es=1
  fi

  if command -v checkupdates >/dev/null 2>&1; then
    updates_source="checkupdates"
    if updates_raw="$(hardhat_updates_capture_with_timeout 15s checkupdates)"; then
      updates_rc=0
    else
      updates_rc=$?
    fi
  elif command -v pacman >/dev/null 2>&1; then
    updates_source="pacman"
    if updates_raw="$(hardhat_updates_capture_with_timeout 15s pacman -Qu)"; then
      updates_rc=0
    else
      updates_rc=$?
    fi
  else
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Verificacion de actualizaciones omitida: pacman/checkupdates no disponible."
      hardhat_audit_add_finding \
        "updates.check.unavailable" \
        "low" \
        "Verificacion de actualizaciones no disponible" \
        "HardHat no pudo encontrar pacman o checkupdates para inspeccionar actualizaciones pendientes." \
        "Instala herramientas de pacman y ejecuta verificaciones de actualizaciones regularmente."
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
      hardhat_audit_add_note "Verificacion de actualizaciones agotada despues de 15s."
      hardhat_audit_add_finding \
        "updates.check.timeout" \
        "low" \
        "Verificacion de actualizaciones agotada" \
        "HardHat detuvo la verificacion de actualizaciones por timeout para evitar bloquear la auditoria." \
        "Ejecuta checkupdates o pacman -Qu manualmente para verificar actualizaciones pendientes."
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

  if [[ "${updates_source}" == "checkupdates" ]]; then
    # checkupdates returns 2 when there are no updates and non-zero in other error scenarios.
    if [[ "${updates_rc}" -eq 0 ]]; then
      updates_confident=1
    elif [[ "${updates_rc}" -eq 2 ]] && [[ -z "${updates_raw}" ]]; then
      updates_confident=1
      updates_count=0
    else
      if [[ "${use_es}" -eq 1 ]]; then
        hardhat_audit_add_note "Estado de actualizaciones pendientes: desconocido (verificacion no concluyente)."
        hardhat_audit_add_finding \
          "updates.check.inconclusive" \
          "low" \
          "Verificacion de actualizaciones no concluyente" \
          "HardHat no pudo confirmar con confianza el estado de actualizaciones pendientes con checkupdates." \
          "Ejecuta checkupdates manualmente y valida mirrors/estado de red/repositorios."
      else
        hardhat_audit_add_note "Pending updates status: unknown (check inconclusive)."
        hardhat_audit_add_finding \
          "updates.check.inconclusive" \
          "low" \
          "Update check inconclusive" \
          "HardHat could not confidently confirm pending updates status using checkupdates." \
          "Run checkupdates manually and validate mirrors/network/repository state."
      fi
      return 0
    fi
  elif [[ "${updates_source}" == "pacman" ]]; then
    if [[ "${updates_rc}" -eq 0 ]]; then
      updates_confident=1
    else
      if [[ "${use_es}" -eq 1 ]]; then
        hardhat_audit_add_note "Estado de actualizaciones pendientes: desconocido (pacman -Qu no concluyente)."
        hardhat_audit_add_finding \
          "updates.check.inconclusive" \
          "low" \
          "Verificacion de actualizaciones no concluyente" \
          "HardHat no pudo confirmar con confianza el estado de actualizaciones pendientes con pacman -Qu." \
          "Ejecuta pacman -Qu manualmente y valida mirrors/estado de red/repositorios."
      else
        hardhat_audit_add_note "Pending updates status: unknown (pacman -Qu inconclusive)."
        hardhat_audit_add_finding \
          "updates.check.inconclusive" \
          "low" \
          "Update check inconclusive" \
          "HardHat could not confidently confirm pending updates status with pacman -Qu." \
          "Run pacman -Qu manually and validate mirrors/network/repository state."
      fi
      return 0
    fi
  fi

  if [[ "${updates_confident}" -ne 1 ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Estado de actualizaciones pendientes: desconocido (verificacion no concluyente)."
    else
      hardhat_audit_add_note "Pending updates status: unknown (check inconclusive)."
    fi
    return 0
  fi

  if [[ -n "${updates_raw}" ]]; then
    updates_count="$(grep -c '.' <<<"${updates_raw}" || true)"
  fi

  if [[ "${use_es}" -eq 1 ]]; then
    hardhat_audit_add_note "Actualizaciones de paquetes pendientes detectadas: ${updates_count}."
  else
    hardhat_audit_add_note "Pending package updates detected: ${updates_count}."
  fi

  if ((updates_count >= 50)); then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "updates.pending.high" \
        "high" \
        "Muchas actualizaciones de sistema pendientes" \
        "Un numero alto de actualizaciones pendientes puede incluir correcciones de seguridad sin aplicar." \
        "Revisa y aplica actualizaciones del sistema lo antes posible."
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
        "Actualizaciones de sistema pendientes" \
        "Varias actualizaciones de paquetes estan pendientes y pueden incluir parches de seguridad." \
        "Aplica actualizaciones pendientes en una ventana de mantenimiento controlada."
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
        "Pocas actualizaciones pendientes" \
        "Hay actualizaciones pendientes y mantener paquetes al dia reduce exposicion." \
        "Aplica actualizaciones pendientes pronto."
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