# Arquitectura de HardHat

## Alcance actual
HardHat es una CLI en Bash, enfocada en Arch Linux, para auditoria baseline de seguridad y hardening guiado de UFW.

## Diseno de alto nivel
- `bin/hardhat`: entrypoint CLI, parsing de flags globales y despacho de comandos.
- `lib/`: utilidades compartidas (logging, json, deteccion, validacion, privilegios, backup, confirmacion).
- `modules/`: modulos funcionales (`audit`, `firewall`, `ports`, `services`, `ssh_audit`, `updates`).
- `install.sh`: flujo de instalacion para exponer comando del sistema.

## Flujo de ejecucion
1. El usuario ejecuta `hardhat`.
2. El entrypoint parsea opciones globales y argumentos.
3. Se aplica guarda de compatibilidad Arch para comandos operativos.
4. El comando se enruta al modulo correspondiente.
5. El modulo recolecta datos, evalua y renderiza salida.
6. En `firewall apply`, si falta UFW, se informa riesgo, se muestra plan y se ofrece instalacion guiada antes de aplicar baseline.

## Modelo de datos
- Los checks generan notas y hallazgos estructurados.
- Cada hallazgo incluye `id`, `severity`, `title`, `description`, `recommendation`.
- El modulo de auditoria calcula score y severidad general.
- El render JSON expone objetos estables para automatizacion.
- En modo `--json`, `stdout` se reserva para JSON y los logs operativos se emiten por `stderr`.

## Modelo de seguridad
- Sin cambios silenciosos.
- `--dry-run` simula flujo de apply sin tocar estado del sistema.
- Si UFW no existe, `firewall apply` informa exposicion, muestra plan y pide confirmacion explicita antes de instalar con pacman.
- Backups en `firewall apply` con politica contextual:
  - UFW preexistente: backup obligatorio de configuracion existente.
  - UFW recien instalado: no bloquear si aun no hay archivos; respaldar cualquier archivo existente antes de modificar.
- Si existe configuracion y backup falla, apply se aborta.
- Confirmacion global requerida salvo uso de `--yes`.
- Rollback automatico fuera de alcance del MVP.

## Modelo de logs
- Logs legibles por humanos durante ejecucion.
- `firewall apply` registra eventos en `/var/log/hardhat.log` cuando hay permisos.

## Restricciones actuales
- Solo Arch Linux.
- Solo backend UFW.
- Parsing intencionalmente liviano, con degradacion controlada si cambian salidas de comandos.
