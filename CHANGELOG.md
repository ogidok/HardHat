# CHANGELOG

## 1.0.8 - 2026-06-29

Primera release estable Arch-first, orientada a publicacion en AUR.

### CLI y UX
- Comandos core estabilizados: `audit`, `firewall audit`, `firewall apply`, `uninstall`, `menu`, `language`.
- Ayudas, errores de uso y mensajes ES/EN normalizados para mayor consistencia.
- Contrato de exit codes consolidado (`0`, `2`, `10`, `20`, `30`).

### JSON y automatizacion
- En comandos con `--json`, `stdout` reservado para JSON valido.
- Diagnosticos operativos en `stderr` para no romper consumo automatizado.
- Envoltura JSON minima consistente en comandos soportados.

### Packaging Arch/AUR
- `PKGBUILD` y `.SRCINFO` alineados para build reproducible.
- Fuente del paquete basada en tag/release versionado (`v1.0.8`) con checksum SHA256.
- Instalacion empaquetada validada para flujo `makepkg` + `pacman -U/-R`.

### Calidad y documentacion
- Suite de pruebas shell actualizada (smoke, edge cases, integracion segura y unitarios).
- Documentacion operativa y de release consolidada (`README`, `RELEASE_POLICY`, `RELEASE_CHECKLIST`, `TODO`, troubleshooting).
