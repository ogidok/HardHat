# TODOs (Post-MVP)

Nota de estado:
- Este archivo lista solo pendientes reales post-MVP.
- Ya implementado en el estado actual: `audit`, `firewall audit`, `firewall apply`, instalacion, `hardhat uninstall` (con wrapper de compatibilidad `uninstall.sh`), salida JSON, backups y documentacion base del proyecto.

## Prioridad 1
- Implementar flujo real de `menu`.
- Mejorar deteccion de regla SSH en `firewall apply` (menos heuristica).
- Mejorar validacion post-apply (verificar reglas esperadas, no solo activo/default).
- Endurecer manejo de rutas interactivas con sudo/privilegios.

## Prioridad 2
- Agregar salida JSON opcional para resumen de `firewall apply`.
- Completar ayuda especifica por comando y subcomando en todos los modulos.
- Normalizar catalogo de mensajes para consistencia total.
- Mejorar resiliencia del parser ante variaciones de salida de UFW.

## Prioridad 3
- Definir estrategia de tests (unitarios shell + smoke tests de integracion).
- Agregar PKGBUILD para empaquetado en Arch.
- Expandir documentacion de troubleshooting y modelo de permisos.
