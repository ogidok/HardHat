# TODO (Roadmap Arch-first)

Actualizado: 2026-06-29 (roadmap limpio + politica/checklist de release)

Estado resumido:
- Ya implementado: comandos MVP (`audit`, `firewall audit`, `firewall apply`, `uninstall`, `menu`, `language`), salida JSON base, contrato de exit codes MVP, suite de tests actual (smoke/integration/unit + edge cases), packaging base Arch (`PKGBUILD` + `.SRCINFO`) y documentacion operativa principal.

## Prioridad alta (bloqueadores de primera release estable)

### 1) Contrato CLI/JSON v1 congelado y verificable
- Mantener alineada la politica minima de `docs/RELEASE_POLICY.md` con `README.md` y el comportamiento observable.
- Documentar matriz final de `status.result` y exit code esperado (`0/2/10/20/30`) para comandos core.
- Añadir tests de contrato con validacion de tipos minimos (no solo presencia de claves) para JSON de `audit`, `firewall audit`, `firewall apply`, `uninstall`.

### 2) Validacion real de release en Arch
- Ejecutar `docs/RELEASE_CHECKLIST.md` completo en Arch limpio (sin estado previo) y en Arch con UFW ya presente.
- Validar ciclo empaquetado real: build, install, upgrade y remove con `makepkg` + `pacman -U/-R`.
- Registrar resultados de validacion (comandos ejecutados y estado) en el ciclo de release.

### 3) PKGBUILD de release formal
- Pasar de build local desde checkout a `source` versionado (tag/tarball) y `sha256sums` reales.
- Confirmar coherencia estricta entre `pkgver`, `bin/hardhat` (`HARDHAT_VERSION`) y `CHANGELOG.md`.

## Prioridad media (post-release temprana)

### Robustez operativa
- Expandir integracion determinista para caminos de warning parcial (`10`) y error operativo (`20`) en escenarios reproducibles.
- Mejorar trazabilidad de errores operativos (logging mas consistente) sin cambiar UX publica.

### Mantenimiento interno
- Reducir duplicacion menor de parseo/validacion de argumentos sin refactor grande.

## Fuera de alcance por ahora

- Soporte oficial multi-distro.
- Backends firewall alternativos (nftables/firewalld).
- Politica de rollback automatico.
- Features no criticas (exportes, completions).