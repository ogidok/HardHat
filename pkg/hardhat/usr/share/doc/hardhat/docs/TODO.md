# TODOs (Post-MVP)

Nota de estado:
- Este archivo lista solo pendientes reales post-MVP.
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
  - documentacion base del proyecto
  - smoke tests iniciales para help/uninstall
- `accsi.txt` se mantiene temporalmente en la raiz como asset/splash usado por el proyecto; su reubicacion puede evaluarse mas adelante y no es un pendiente prioritario actual.

## Prioridad 1
- Sin pendientes inmediatos.

## Prioridad 2
- Sin pendientes inmediatos.

## Prioridad 3
- Expandir cobertura de tests sobre escenarios operativos avanzados (sin perder seguridad ni simplicidad).