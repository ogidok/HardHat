# Troubleshooting y Modelo de Permisos

Esta guia resume como diagnosticar problemas frecuentes en HardHat sin adivinar.

## Modelo de permisos

Principio actual:
- HardHat intenta operar sin privilegios para lectura/auditoria.
- Solo exige root/sudo cuando hay cambios reales en rutas o estado del sistema.

Resumen por flujo:
- `hardhat audit`: sin cambios del sistema; puede ejecutarse sin root/sudo.
- `hardhat firewall audit`: sin cambios del sistema; puede tener visibilidad parcial de UFW sin permisos suficientes.
- `hardhat firewall apply`:
  - en `--dry-run`, no requiere root/sudo para simular plan;
  - sin `--dry-run`, requiere root/sudo para instalar/configurar UFW, escribir backups y log operativo.
- `hardhat uninstall`:
  - en `--dry-run`, simula sin borrar;
  - sin `--dry-run`, requiere root/sudo cuando toca rutas de sistema (`/opt`, `/usr`, `/etc`).
- `./install.sh`:
  - en `--dry-run`, simula;
  - sin `--dry-run`, requiere root/sudo para escribir runtime/comando/config global.
- `hardhat menu`: requiere terminal TTY interactiva; no compatible con `--json`.

## Dry-run y yes

`--dry-run`:
- Muestra plan y acciones simuladas.
- No debe modificar archivos ni estado de firewall.
- Recomendado como primer paso antes de operaciones reales.

`--yes`:
- Omite confirmaciones interactivas.
- No omite validaciones de seguridad ni requisitos de privilegios.

## Rutas operativas importantes

- Runtime: `/opt/hardhat`
- Comando: `/usr/local/bin/hardhat`
- Config global: `/etc/hardhat/config`
- Config usuario: `~/.config/hardhat/config`
- Backups firewall apply: `/var/backups/hardhat/firewall`
- Log firewall apply: `/var/log/hardhat.log`

## Problemas frecuentes

### 1) sudo no esta disponible

Sintoma:
- error indicando que no se puede ejecutar accion privilegiada o que sudo no esta disponible.

Diagnostico rapido:
- `command -v sudo`
- `id -u`

Que hacer:
- primero ejecutar el mismo flujo con `--dry-run` para validar plan;
- luego ejecutar como root o instalar/configurar sudo.

### 2) No root/sudo en install/uninstall/apply

Sintoma:
- fallo al escribir en `/opt`, `/usr/local/bin`, `/etc` o al aplicar reglas UFW.

Diagnostico rapido:
- revisar si el comando es de cambios reales (sin `--dry-run`);
- revisar usuario actual con `id -u`.

Que hacer:
- validar con `--dry-run`;
- repetir con privilegios adecuados.

### 3) UFW no instalado

Sintoma:
- auditoria reporta backend ausente o `firewall apply` indica instalacion necesaria.

Diagnostico rapido:
- `command -v ufw`

Que hacer:
- en Arch, ejecutar `hardhat firewall apply` y seguir flujo guiado;
- usar `--dry-run` antes para revisar plan.

### 4) menu en entorno no interactivo

Sintoma:
- `hardhat menu` falla en pipelines, CI o redirecciones.

Diagnostico rapido:
- comprobar si stdin/stdout son TTY interactivos.

Que hacer:
- usar comandos directos (`audit`, `firewall audit`, etc.) en scripts/CI;
- reservar `menu` para sesiones interactivas.

### 5) JSON mezclado con logs

Comportamiento esperado actual:
- en `--json`, `stdout` se reserva para JSON;
- mensajes operativos pueden ir por `stderr`.

Diagnostico rapido:
- separar streams al probar:
  - `hardhat audit --json >out.json 2>err.log`

Que hacer:
- consumir JSON desde `stdout`;
- tratar `stderr` como canal de diagnostico.

### 6) Instalacion o desinstalacion incompleta

Sintoma:
- comando presente pero runtime inconsistente, o residuos de configuracion/rutas.

Diagnostico rapido:
- revisar existencia de:
  - `/opt/hardhat`
  - `/usr/local/bin/hardhat`
  - `/etc/hardhat/config`
  - `~/.config/hardhat/config`

Que hacer:
- ejecutar primero flujo en `--dry-run` para validar plan real;
- repetir install/uninstall con parametros correctos;
- usar `hardhat uninstall --yes --purge-config` si corresponde limpieza completa de config.

## Limitaciones actuales

- Sin rollback automatico en `firewall apply`.
- Soporte oficial actual: Arch Linux + UFW.
- Parte de validaciones operativas depende de herramientas del sistema (`ufw`, `pacman`, `sudo`).
