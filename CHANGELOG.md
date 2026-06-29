# CHANGELOG

## Version objetivo actual
- Version CLI (`HARDHAT_VERSION`): `1.0.8`
- Version de paquete (`pkgver`): `1.0.8`
- Estado: objetivo para primera publicacion estable Arch-first/AUR.
- Packaging AUR: fuente migrada a tarball por tag/release esperado (`v1.0.8`).

## Nota de estado
- Este archivo registra el estado consolidado y los hitos relevantes ya implementados.
- Ya implementado en el estado actual:
  - `audit`
  - `firewall audit`
  - `firewall apply`
  - `firewall apply --json` (resumen final)
  - validacion post-apply reforzada (activo, defaults de entrada/salida y regla SSH esperada)
  - catalogo de mensajes normalizado para mayor consistencia ES/EN
  - parser de UFW mas resiliente ante variaciones comunes de salida
  - deteccion de regla SSH en `firewall apply` mas confiable (menos heuristica)
  - manejo de rutas interactivas con sudo/privilegios endurecido
  - flujo interactivo real para `menu`
  - instalacion
  - `hardhat uninstall` (con wrapper de compatibilidad `uninstall.sh`)
  - salida JSON base
  - backups
  - ayuda global y ayuda especifica principal de la CLI
  - pasada final de consistencia entre ayuda, errores de uso, smoke tests y README
  - estrategia base de tests definida (smoke CLI + integracion segura + unitarios shell)
  - documentacion de troubleshooting y modelo de permisos expandida
  - PKGBUILD base para empaquetado en Arch
  - PKGBUILD endurecido para flujo Arch-first (ruta/licencia/docs/options)
  - documentacion base del proyecto
  - roadmap pendiente limpiado y priorizado en `docs/TODO.md`
  - politica minima de release en `docs/RELEASE_POLICY.md`
  - checklist de release reforzado con gates de shellcheck/shfmt/tests/PKGBUILD en `docs/RELEASE_CHECKLIST.md`
  - smoke tests iniciales para help/uninstall
- `accsi.txt` se mantiene temporalmente en la raiz como asset/splash usado por el proyecto; su reubicacion puede evaluarse mas adelante y no es un pendiente prioritario actual.
