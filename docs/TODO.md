# TODO

_Actualizado: 2026-06-28_

## Prioridad alta

### Testing
- [x] Definir estrategia de tests simple en Bash
- [x] Crear `tests/run_all.sh`
- [x] Agregar smoke tests para:
  - [x] `hardhat help`
  - [x] `hardhat audit`
  - [x] `hardhat firewall audit`
  - [x] `hardhat firewall apply --dry-run`
  - [x] `hardhat uninstall --dry-run`
- [x] Verificar que `--json` produzca salida parseable en comandos principales
- [x] Documentar cómo correr tests

### CLI / UX
- [x] Unificar help/usage principal y de subcomandos
- [ ] Revisar consistencia de nombres de flags
- [ ] Revisar mensajes de error para inputs inválidos
- [ ] Asegurar códigos de salida coherentes
- [x] Agregar ejemplos de uso a comandos principales

### Output / JSON
- [ ] Definir esquema mínimo estable para `--json`
- [ ] Garantizar que errores en modo JSON también sean consistentes
- [ ] Revisar campos comunes compartidos entre comandos
- [ ] Evitar mezclar logs humanos con salida JSON

### Firewall
- [ ] Endurecer parser de UFW frente a variantes reales de salida
- [ ] Mejorar validación previa antes de `firewall apply`
- [ ] Revisar comportamiento cuando UFW no está instalado
- [ ] Revisar comportamiento cuando UFW está instalado pero inactivo
- [ ] Mejorar mensajes de recomendación tras `firewall audit`

### Seguridad / confiabilidad
- [ ] Revisar uso de `sudo` y privilegios mínimos
- [ ] Confirmar operaciones peligrosas con mensajes claros
- [ ] Validar precondiciones antes de cambios de sistema
- [ ] Mejorar manejo de dependencias faltantes

---

## Prioridad media

### Arch Linux first
- [x] Documentar alcance oficial: soporte enfocado en Arch Linux
- [ ] Validar flujos en Arch limpio
- [ ] Validar flujos en Arch con paquetes ya presentes
- [ ] Revisar integración con `pacman`
- [x] Crear `PKGBUILD`
- [ ] Probar instalación desde `PKGBUILD`

### Documentación
- [x] Mejorar `README.md` con quickstart
- [ ] Agregar sección de filosofía y alcance del proyecto
- [x] Documentar ejemplos reales de `audit`, `firewall audit`, `firewall apply`
- [ ] Agregar tabla de comandos y flags
- [ ] Documentar limitaciones actuales

### Logging / observabilidad
- [ ] Definir niveles de verbosidad
- [ ] Agregar modo verbose consistente
- [ ] Separar claramente stdout/stderr
- [ ] Hacer trazable por qué una validación falla

### Refactor técnico
- [ ] Extraer helpers reutilizables de output
- [ ] Extraer helpers reutilizables de validación
- [ ] Reducir duplicación en parsing de argumentos
- [ ] Separar mejor lógica de negocio de rendering de salida

---

## Prioridad baja

### Multi-distro (fase posterior)
- [ ] Diseñar una capa de detección de distro
- [ ] Definir qué partes son específicas de Arch
- [ ] Identificar comandos dependientes de `pacman`
- [ ] Evaluar primer objetivo fuera de Arch:
  - [ ] Debian/Ubuntu
  - [ ] Fedora
- [ ] Diseñar interfaz para backends de package manager
- [ ] Diseñar estrategia para firewalls no-UFW o diferencias por distro
- [ ] Documentar matriz de compatibilidad

### Features futuras
- [ ] Modo `doctor` o diagnóstico general
- [ ] Reporte consolidado de hallazgos
- [ ] Exportar reporte a archivo
- [ ] Modo no interactivo más estricto
- [ ] Colores configurables / desactivables
- [ ] Shell completions

### Release / mantenimiento
- [ ] Definir versión inicial estable
- [x] Agregar changelog
- [ ] Definir política de compatibilidad CLI
- [ ] Checklist de release
- [ ] Licencia y metadatos finales

---

## Decisión de roadmap

### Ahora
- [ ] Consolidar HardHat como herramienta Arch-first

### Después
- [ ] Expandir a multi-distro solo cuando:
  - [ ] tests básicos estén firmes
  - [ ] CLI y JSON sean estables
  - [ ] flujo principal en Arch esté bien documentado
  - [ ] exista una capa de abstracción mínima para package managers