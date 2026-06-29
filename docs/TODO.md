# TODO (Post-MVP, Arch-first)

Actualizado: 2026-06-28 (ciclo JSON/exit-codes)

Estado resumido:
- Ya implementado: `audit`, `firewall audit`, `firewall apply`, `uninstall`, `menu`, ES/EN, salida JSON base, tests (smoke/integration/unit), `README` ampliado, troubleshooting, `PKGBUILD` base y `CHANGELOG`.

## Prioridad alta

### CLI / UX (consistencia)
- Cerrar inconsistencias residuales de flags/help en comandos no cubiertos por contrato JSON (principalmente `menu` y `language`).
- Homologar mensajes de error y sugerencias de recuperación en rutas no JSON.

### Output / JSON (contrato estable)
- Congelar contrato JSON v1 documentado para `audit`, `firewall audit`, `firewall apply`, `uninstall`.
- Documentar matriz de `status.result` + exit codes esperados por comando.
- Añadir validación de tipos mínimos del contrato en tests (no solo presencia de campos).

### Testing (cobertura adicional)
- Expandir integración para casos operativos reales de `firewall apply` (con y sin UFW instalado, en Arch).
- Agregar casos de error operativo (`20`) y warning parcial (`10`) de forma determinista.
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
- Cerrar validación de contrato JSON v1 en integración (tipos + resultados esperados).
- Completar validación de empaquetado Arch en ciclo de prueba real.

## Después
- Ejecutar release candidate Arch-first con checklist mínimo.
- Reabrir discusión multi-distro solo tras estabilidad de CLI, JSON y tests en Arch.