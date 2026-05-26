#!/usr/bin/env bash

hardhat_module_ports_collect_audit() {
  local raw
  local -a lines=()
  local use_es=0

  if [[ "${HARDHAT_LANG:-en}" == "es" ]]; then
    use_es=1
  fi

  if command -v ss >/dev/null 2>&1; then
    raw="$(ss -lntuH 2>/dev/null || true)"
  elif command -v netstat >/dev/null 2>&1; then
    raw="$(netstat -lntu 2>/dev/null | tail -n +3 || true)"
  else
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "Check de puertos omitido: ss/netstat no disponible."
      hardhat_audit_add_finding \
        "ports.check.unavailable" \
        "low" \
        "Check de puertos no disponible" \
        "No se encontro una herramienta soportada para inspeccionar puertos en escucha." \
        "Instala iproute2 para disponer del comando ss."
    else
      hardhat_audit_add_note "Port checks skipped: ss/netstat unavailable."
      hardhat_audit_add_finding \
        "ports.check.unavailable" \
        "low" \
        "Port check unavailable" \
        "No supported tool found to inspect listening ports." \
        "Install iproute2 for ss command availability."
    fi
    return 0
  fi

  if [[ -z "${raw}" ]]; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_note "No se detectaron puertos TCP/UDP en escucha con el contexto actual de usuario."
    else
      hardhat_audit_add_note "No listening TCP/UDP ports detected by current user context."
    fi
    return 0
  fi

  while IFS= read -r line; do
    [[ -n "${line}" ]] && lines+=("${line}")
  done <<<"${raw}"

  if [[ "${use_es}" -eq 1 ]]; then
    hardhat_audit_add_note "Entradas de puertos en escucha detectadas: ${#lines[@]}."
  else
    hardhat_audit_add_note "Listening port entries detected: ${#lines[@]}."
  fi

  local exposed_count
  exposed_count="$(printf '%s\n' "${lines[@]}" | grep -Ec '(^|[[:space:]])(0\.0\.0\.0|\*|\[::\]|::):' || true)"
  if [[ -n "${exposed_count}" ]] && ((exposed_count > 0)); then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "ports.listen.exposed" \
        "medium" \
        "Sockets publicos en escucha detectados" \
        "Algunos servicios estan escuchando en interfaces comodin o publicas." \
        "Limita bind addresses innecesarias y restringe acceso entrante con reglas de firewall."
    else
      hardhat_audit_add_finding \
        "ports.listen.exposed" \
        "medium" \
        "Public listening sockets detected" \
        "Some services are listening on wildcard or public interfaces." \
        "Limit unnecessary bind addresses and restrict incoming access with firewall rules."
    fi
  fi

  if printf '%s\n' "${lines[@]}" | grep -Eq '(:23[[:space:]]|:23$|\*:23[[:space:]])'; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "ports.telnet.open" \
        "high" \
        "El puerto Telnet parece abierto" \
        "El puerto 23 esta en escucha, lo que suele indicar acceso remoto inseguro en texto plano." \
        "Deshabilita servicios Telnet y usa SSH con configuracion reforzada."
    else
      hardhat_audit_add_finding \
        "ports.telnet.open" \
        "high" \
        "Telnet port appears open" \
        "Port 23 is listening, which usually indicates insecure plaintext remote access." \
        "Disable Telnet services and use SSH with hardened configuration."
    fi
  fi

  if printf '%s\n' "${lines[@]}" | grep -Eq '(:3389[[:space:]]|:3389$|\*:3389[[:space:]])'; then
    if [[ "${use_es}" -eq 1 ]]; then
      hardhat_audit_add_finding \
        "ports.rdp.open" \
        "medium" \
        "El puerto RDP parece abierto" \
        "El puerto 3389 esta en escucha y puede aumentar la superficie de ataque remoto si esta expuesto." \
        "Restringe acceso RDP a redes confiables y aplica controles de firewall."
    else
      hardhat_audit_add_finding \
        "ports.rdp.open" \
        "medium" \
        "RDP port appears open" \
        "Port 3389 is listening and may increase remote attack surface if exposed." \
        "Restrict RDP access to trusted networks and enforce firewall controls."
    fi
  fi
}

hardhat_module_ports_check() {
  hardhat_module_ports_collect_audit
  return 0
}