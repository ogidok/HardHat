# Release Policy (Arch-first)

Politica minima para declarar una release estable de HardHat.

## 1) Criterio de estabilidad suficiente

Se considera lista una release estable cuando:
- Los comandos core (`audit`, `firewall audit`, `firewall apply`, `uninstall`, `help`, `version`) mantienen comportamiento observable consistente.
- La suite `bash tests/run_all.sh` pasa en Arch Linux.
- `shellcheck` y `shfmt -d` no reportan incumplimientos en scripts del proyecto.
- El flujo empaquetado Arch (`makepkg` + `pacman -U/-R`) fue validado en al menos un entorno limpio.
- `README.md`, `CHANGELOG.md`, `PKGBUILD` y `.SRCINFO` estan alineados en version y alcance.

## 2) Politica de compatibilidad CLI/JSON

Objetivo para la primera linea estable (v1.x):
- Mantener estables nombres de comandos y flags globales documentados.
- Mantener estables exit codes actuales: `0`, `2`, `10`, `20`, `30`.
- Mantener estable la envoltura JSON minima (`metadata`, `command`, `status`, `summary`, `notes`) en comandos que soportan JSON.

Regla para cambios incompatibles:
- Evitar breaking changes en versiones patch.
- Cualquier cambio incompatible de CLI o JSON requiere version mayor y nota explicita en `CHANGELOG.md`.

## 3) Soporte oficial actual

Soporte oficial en esta etapa:
- Distro: Arch Linux (Arch-first).
- Backend firewall soportado: UFW.
- Flujo de paquete recomendado: `makepkg` + `pacman -U/-R`.

## 4) Fuera de alcance por ahora

No forma parte del compromiso de la primera release estable:
- Soporte oficial multi-distro.
- Backends de firewall alternativos (nftables/firewalld).
- Rollback automatico de cambios de firewall.
- Nuevas features no criticas fuera del alcance actual.

## 5) Gate de release

Una release se aprueba solo si `docs/RELEASE_CHECKLIST.md` se completa sin bloqueadores abiertos.
