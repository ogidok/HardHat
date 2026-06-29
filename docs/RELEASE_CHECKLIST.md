# Release Checklist (Arch-first)

Checklist minimo para preparar una primera release de HardHat en Arch.

## 1) Versionado
- [ ] Confirmar version en `bin/hardhat` (`HARDHAT_VERSION`).
- [ ] Alinear `pkgver` en `PKGBUILD`.
- [ ] Regenerar `.SRCINFO` desde `PKGBUILD` actualizado.

## 2) Calidad minima
- [ ] `bash -n bin/hardhat lib/*.sh modules/*.sh tests/*.sh`
- [ ] `bash tests/run_all.sh`
- [ ] Revisar que los smoke tests no requieran cambios reales del sistema.

## 3) Empaquetado Arch
- [ ] `makepkg --printsrcinfo > .SRCINFO`
- [ ] `makepkg -f`
- [ ] Instalar localmente: `sudo pacman -U ./hardhat-*.pkg.tar.*`

## 4) Verificacion post-instalacion
- [ ] `hardhat --version`
- [ ] `hardhat help`
- [ ] `hardhat audit --json`
- [ ] `hardhat --json firewall apply --dry-run --yes`

## 5) Validacion de desinstalacion empaquetada
- [ ] Desinstalar con paquete: `sudo pacman -R hardhat`
- [ ] Verificar que `hardhat` ya no este en PATH.

## 6) Documentacion
- [ ] Verificar coherencia entre `README.md`, `PKGBUILD` y comportamiento CLI.
- [ ] Actualizar `CHANGELOG.md` con los cambios del ciclo.

## Notas
- El flujo recomendado para instalaciones empaquetadas es `pacman -U/-R`.
- `install.sh` y `hardhat uninstall` se mantienen para instalaciones manuales/desarrollo.
- Para release formal faltara definir fuente versionada (`source`) y checksums de artefactos de release en `PKGBUILD`.
