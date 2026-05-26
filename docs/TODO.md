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
  - instalacion
  - `hardhat uninstall` (con wrapper de compatibilidad `uninstall.sh`)
  - salida JSON base
  - backups
  - ayuda global y ayuda especifica principal de la CLI
  - documentacion base del proyecto
  - smoke tests iniciales para help/uninstall
- `accsi.txt` se mantiene temporalmente en la raiz como asset/splash usado por el proyecto; su reubicacion puede evaluarse mas adelante y no es un pendiente prioritario actual.

## Prioridad 1
- Implementar flujo real de `menu`.

## Prioridad 2
- Hacer pasada final de consistencia entre ayuda, errores de uso, smoke tests y README para asegurar alineacion completa con la CLI real.

## Prioridad 3
- Definir estrategia de tests (unitarios shell + smoke tests de integracion).
- Agregar PKGBUILD para empaquetado en Arch.
- Expandir documentacion de troubleshooting y modelo de permisos.