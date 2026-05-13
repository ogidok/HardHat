# TODOs (Post-MVP)

## Prioridad 1
- Implementar flujo real de `menu`.
- Mejorar deteccion de regla SSH en `firewall apply` (menos heuristica).
- Mejorar validacion post-apply (verificar reglas esperadas, no solo activo/default).
- Endurecer manejo de rutas interactivas con sudo/privilegios.

## Prioridad 2
- Agregar salida JSON opcional para resumen de `firewall apply`.
- Agregar ayuda especifica por comando y subcomando en todos los modulos.
- Normalizar catalogo de mensajes para consistencia total.
- Mejorar resiliencia del parser ante variaciones de salida de UFW.

## Prioridad 3
- Definir estrategia de tests (unitarios shell + smoke tests de integracion).
- Agregar PKGBUILD para empaquetado en Arch.
- Agregar comando dedicado de desinstalacion.
- Expandir documentacion de troubleshooting y modelo de permisos.
