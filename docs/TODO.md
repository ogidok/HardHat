# TODO (Post-MVP, Arch-first)

Actualizado: 2026-06-28

Estado resumido:
- Ya implementado: `audit`, `firewall audit`, `firewall apply`, `uninstall`, `menu`, ES/EN, salida JSON base, tests (smoke/integration/unit), `README` ampliado, troubleshooting, `PKGBUILD` base y `CHANGELOG`.

## Prioridad alta

### CLI / UX (consistencia)
- Unificar semántica de flags globales y por comando (`--help`, `--json`, `--dry-run`, `--yes`).
- Revisar y normalizar códigos de salida en errores de uso, validación y ejecución.
- Homologar mensajes de error y sugerencias de recuperación entre comandos.

### Output / JSON (contrato estable)
- Definir contrato mínimo v1 de JSON por comando (`audit`, `firewall audit`, `firewall apply`).
- Garantizar consistencia `stdout`/`stderr` en modo JSON para éxito y error.
- Documentar campos obligatorios y opcionales para evitar regresiones.

### Testing (cobertura adicional)
- Expandir smoke/integration para casos negativos críticos (flags inválidas, errores esperados, exit codes).
- Agregar assertions de contrato JSON (campos clave y tipos básicos) en tests existentes.
- Ejecutar corrida regular en Arch real (entorno limpio y entorno con UFW ya presente).

## Prioridad media

### Refactor interno liviano
- Reducir duplicación en parseo/validación de argumentos.
- Extraer helpers comunes de renderizado y validación sin cambiar arquitectura.
- Mejorar trazabilidad interna de fallos operativos (logging consistente).

### Arch packaging y release readiness
- Validar instalación/upgrade/remove con `makepkg` + `pacman -U/-R` en flujo real.
- Alinear `PKGBUILD`/`.SRCINFO` con versión del CLI en cada iteración.
- Definir checklist mínimo de release (versionado, tests, empaquetado, docs).

### Documentación operativa
- Añadir tabla breve de comandos/flags en `README`.
- Consolidar limitaciones actuales del MVP en una sección única y visible.

## Prioridad baja

### Futuro (no ahora)
- Diseñar política formal de compatibilidad de CLI/JSON entre versiones.
- Evaluar mejoras no críticas (`doctor`, exportes, completions) sin ampliar alcance de distro.

## Ahora
- Cerrar consistencia de flags/help/exit codes.
- Congelar contrato JSON v1 y cubrirlo con tests.
- Completar validación de empaquetado Arch en ciclo de prueba real.

## Después
- Ejecutar release candidate Arch-first con checklist mínimo.
- Reabrir discusión multi-distro solo tras estabilidad de CLI, JSON y tests en Arch.