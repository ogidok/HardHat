# Release Checklist (Arch-first)

Checklist minimo para aprobar una primera release estable Arch-first.

## 1) Version y changelog
- [ ] Confirmar `HARDHAT_VERSION` en `bin/hardhat`.
- [ ] Alinear `pkgver` en `PKGBUILD`.
- [ ] Confirmar que `CHANGELOG.md` refleja los cambios del ciclo.

## 2) Calidad de shell y tests
- [ ] Sintaxis: `bash -n bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh tests/*.sh`
- [ ] Lint: `shellcheck -x bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh tests/*.sh`
- [ ] Formato: `shfmt -i 2 -ci -sr -bn -d bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh tests/*.sh`
- [ ] Suite: `bash tests/run_all.sh`

## 3) Revision de UX/CLI observable
- [ ] Verificar `hardhat help`, `hardhat help firewall`, `hardhat help firewall apply`, `hardhat help menu`.
- [ ] Verificar errores de uso representativos (flags invalidas, comando desconocido) y exit code `2`.
- [ ] Verificar que en modo JSON el `stdout` sea JSON valido y diagnosticos operativos queden en `stderr`.

## 4) PKGBUILD y metadata Arch
- [ ] Validar sintaxis: `bash -n PKGBUILD`
- [ ] Regenerar metadata: `makepkg --printsrcinfo > .SRCINFO`
- [ ] Build local: `makepkg -f`
- [ ] Verificar artefacto esperado: `makepkg --packagelist`

## 5) Validacion de instalacion/upgrade/remove
- [ ] Instalar paquete: `sudo pacman -U ./hardhat-*.pkg.tar.*`
- [ ] Reinstalar/upgrade sobre instalacion existente y verificar que no rompe comandos core.
- [ ] Desinstalar con `sudo pacman -R hardhat`.
- [ ] Verificar que `hardhat` ya no este en PATH tras remove.

## 6) Coherencia documental
- [ ] Revisar `README.md` (comandos, limites, rutas y flujo Arch).
- [ ] Revisar `docs/RELEASE_POLICY.md` (criterio de estabilidad y alcance oficial).
- [ ] Revisar `docs/TODO.md` para que no arrastre tareas ya cerradas.

## Notas
- Flujo recomendado para instalacion empaquetada: `pacman -U/-R`.
- `install.sh` y `hardhat uninstall` se mantienen para instalaciones manuales/desarrollo.
- Para release formal se requiere `source` versionado y `sha256sums` reales en `PKGBUILD`.
