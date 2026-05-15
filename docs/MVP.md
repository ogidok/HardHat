# Alcance del MVP de HardHat

## Objetivo
Entregar una primera iteracion estable de una CLI de seguridad para Arch Linux, con auditoria util y aplicacion controlada de baseline de UFW.

## Implementado en el MVP actual
- Guardia de compatibilidad para Arch Linux en comandos operativos.
- Estructura modular en Bash.
- Flags globales: `--dry-run`, `--yes`, `--json`, `--verbose`, `--no-color`, `--help`, `--version`.
- Comandos:
  - `hardhat audit` (con salida JSON)
  - `hardhat firewall audit` (con salida JSON y estado explicito de backend esperado/ausente)
  - `hardhat firewall apply` (con plan, instalacion guiada de UFW si falta, backup contextual, confirmacion y validacion)
  - `hardhat menu` (stub)
- Checks baseline:
  - estado y politicas de UFW
  - puertos en escucha
  - servicios activos relevantes
  - senales basicas de configuracion SSH
  - actualizaciones pendientes como senal de riesgo
- Hallazgos estructurados con severidad y recomendacion.
- Calculo de score y resumen para auditoria.
- Instalador para exponer `hardhat` como comando del sistema.

## No implementado todavia
- Soporte multi-distro.
- Backends nftables/iptables.
- Rollback automatico.
- Comportamiento real del menu interactivo.
- Comando dedicado de desinstalacion.
- Tests automatizados.
- Escaneo profundo de CVEs o integracion con herramientas pesadas.

## Compromisos de seguridad del MVP
- Sin cambios silenciosos.
- `--dry-run` no debe modificar el sistema.
- Si UFW no esta instalado, se informa riesgo de exposicion y se solicita confirmacion explicita antes de instalar/configurar.
- Si UFW ya existe, `firewall apply` exige backup de configuracion existente antes de modificar.
- Si UFW se instala en el mismo flujo y aun no hay archivos de configuracion, no se bloquea por backup imposible; si hay archivos, se respaldan.
- Si existe configuracion y falla la creacion de backup, `firewall apply` se aborta.
- Se requiere confirmacion global en apply, salvo `--yes`.
- No hay rollback automatico en esta fase.