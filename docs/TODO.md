# TODO (Post-MVP, Arch-first)

Actualizado: 2026-06-28 (packaging/release-readiness Arch-first)

Estado resumido:
- Ya implementado: `audit`, `firewall audit`, `firewall apply`, `uninstall`, `menu`, ES/EN, salida JSON base, tests (smoke/integration/unit + edge cases de CLI), `README` ampliado, troubleshooting, `CHANGELOG`, `PKGBUILD` endurecido (ruta/licencia/docs/options) y checklist de release en `docs/RELEASE_CHECKLIST.md`.

## Prioridad alta

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
- Ejecutar checklist de `docs/RELEASE_CHECKLIST.md` en entorno Arch limpio.
- Definir `source` versionado y `sha256sums` para release formal (no solo build local desde checkout).

### Documentación operativa
- Añadir tabla breve de comandos/flags en `README`.
- Consolidar limitaciones actuales del MVP en una sección única y visible.

## Prioridad baja

### Futuro (no ahora)
- Diseñar política formal de compatibilidad de CLI/JSON entre versiones.
- Evaluar mejoras no críticas (`doctor`, exportes, completions) sin ampliar alcance de distro.

## Ahora
- Cerrar validación de contrato JSON v1 en integración (tipos + resultados esperados).
- Completar validación de empaquetado Arch en ciclo de prueba real (`pacman -U/-R`, upgrade y verificación post-instalación).

## Después
- Ejecutar release candidate Arch-first con checklist mínimo ya definido.
- Reabrir discusión multi-distro solo tras estabilidad de CLI, JSON y tests en Arch.