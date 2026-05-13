# Alcance del MVP de HardHat

## Objetivo
Entregar una primera iteracion estable de una CLI de seguridad para Arch Linux, con auditoria util y aplicacion controlada de baseline de UFW.

## Implementado en el MVP actual
- Guardia de compatibilidad para Arch Linux en comandos operativos.
- Estructura modular en Bash.
- Flags globales: `--dry-run`, `--yes`, `--json`, `--verbose`, `--no-color`, `--help`, `--version`.
- Comandos:
  - `hardhat audit` (con salida JSON)
  - `hardhat firewall audit` (con salida JSON)
  - `hardhat firewall apply` (con plan, precondicion de backup, confirmacion y validacion)
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
- Si falla la creacion de backup, `firewall apply` se aborta.
- Se requiere confirmacion global en apply, salvo `--yes`.