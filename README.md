![img](https://github.com/user-attachments/assets/b2566fde-e075-4300-b562-acd7a97cc36c)


# HardHat

HardHat es una herramienta CLI para Arch Linux, escrita en Bash, enfocada en auditoria basica de seguridad y aplicacion guiada de cambios de firewall.

## Estado del proyecto

MVP/preview funcional. Lo implementado ya se puede usar desde linea de comandos para validacion tecnica y pruebas controladas.

Importante:
- no hay reversion automatica;
- si se aplican cambios, la restauracion es manual con respaldos;
- si no se pueden crear respaldos, no se aplican cambios.

## Compatibilidad oficial del MVP

- Arch Linux
- backend de firewall: UFW

En el futuro puede evaluarse soporte para otras distribuciones, pero el MVP actual solo soporta Arch Linux.

## Comandos disponibles

```bash
hardhat help
hardhat help firewall
hardhat help firewall apply
hardhat help menu
hardhat version
hardhat audit
hardhat audit --help
hardhat audit --json
hardhat doctor
hardhat doctor --help
hardhat doctor --json
hardhat firewall audit
hardhat firewall audit --help
hardhat firewall audit --json
hardhat firewall apply
hardhat firewall apply --json
hardhat firewall apply --help
hardhat firewall apply --dry-run
hardhat uninstall
hardhat uninstall --help
hardhat uninstall --dry-run --yes
hardhat language --help
hardhat menu
hardhat menu --help
```

Notas:
- `hardhat menu` ofrece un flujo interactivo para acceder a comandos principales del MVP.
- Las flags globales pueden ir antes o despues del comando.

## Flags globales disponibles

```bash
--dry-run
--yes
--json
--verbose
--no-color
-h
--help
--version
```

## Modelo de permisos (operativo)

Objetivo del modelo actual:
- minimizar ejecuciones privilegiadas innecesarias;
- permitir diagnostico/auditoria sin cambios del sistema;
- exigir root/sudo solo cuando hay escritura real en rutas del sistema.

Comandos que normalmente funcionan sin root/sudo:
- `hardhat help`, `hardhat version`, `hardhat language show`, `hardhat language set`;
- `hardhat audit` y `hardhat firewall audit` (pueden reportar visibilidad parcial si no pueden leer estado/reglas de UFW);
- `hardhat menu --help`.

Comandos/modos que pueden requerir privilegios:
- `hardhat firewall apply` (aplica politicas UFW, puede instalar UFW y escribir log operativo);
- `hardhat uninstall` fuera de `--dry-run` cuando afecta rutas de sistema;
- `./install.sh` fuera de `--dry-run` para escribir en `/opt`, `/usr/local/bin` y `/etc`.

Comportamiento de `--dry-run` en flujos sensibles:
- `hardhat firewall apply --dry-run`: no aplica cambios de firewall, no instala paquetes y no exige root/sudo para simular plan;
- `hardhat uninstall --dry-run`: muestra plan y acciones simuladas sin borrar archivos;
- `./install.sh --dry-run`: muestra plan y operaciones simuladas de escritura/enlace.

Comportamiento de `--yes`:
- omite prompts de confirmacion interactiva;
- no desactiva validaciones de seguridad ni requisitos tecnicos del flujo;
- util para ejecucion no interactiva controlada (idealmente junto a `--dry-run` en validaciones).

Si sudo no esta disponible:
- cualquier accion privilegiada real falla con error explicito;
- modos de solo lectura o simulacion (`--dry-run`) siguen siendo la via recomendada para diagnostico.

Rutas de sistema relevantes hoy:
- runtime: `/opt/hardhat`;
- comando: `/usr/local/bin/hardhat`;
- config global: `/etc/hardhat/config`;
- config de usuario: `~/.config/hardhat/config`;
- backups de firewall apply: `/var/backups/hardhat/firewall`;
- log de firewall apply: `/var/log/hardhat.log`.

## Que hace hoy el MVP

### `hardhat menu`

Abre un menu interactivo (TTY) como capa de conveniencia sobre comandos existentes.

Opciones actuales:
- ejecutar `audit`;
- ejecutar `firewall audit`;
- ejecutar `firewall apply`;
- ejecutar `uninstall`;
- ver idioma actual (`language show`);
- cambiar idioma (`language set`);
- salir.

Notas:
- no reemplaza validaciones ni confirmaciones de los flujos reales;
- si se invoca con `--json`, falla de forma explicita por incompatibilidad con modo interactivo;
- si no hay TTY interactiva, falla con mensaje claro.

### `hardhat audit`

Ejecuta una auditoria de linea base y devuelve:
- resumen;
- score;
- severidad general;
- hallazgos estructurados;
- recomendaciones deduplicadas.

Checks actuales:
- estado de UFW (instalado/activo/politica por defecto cuando es posible);
- puertos en escucha (con deteccion basica de exposicion);
- servicios activos relevantes;
- senales basicas de SSH inseguro;
- actualizaciones pendientes.

Salida:
- humana por defecto;
- JSON estable con metadatos, sistema, resumen, notas, hallazgos y recomendaciones.

Comportamiento de salida con `--json`:
- `stdout` contiene solo JSON valido.
- no se imprime banner ASCII ni logs informativos `[INFO]`.
- advertencias o errores relevantes pueden emitirse por `stderr`.

Contrato JSON minimo (MVP):
- `metadata`
- `command`
- `status`
- `summary`
- `notes`
- `findings` y `recommendations` cuando aplica

### `hardhat doctor`

Ejecuta diagnostico general seguro y de solo lectura para validar estado del entorno.

Checks minimos actuales:
- compatibilidad de plataforma Arch-first;
- herramientas relevantes (`bash`, `pacman`, `sudo`, `ufw`);
- presencia e integridad basica de runtime/binario/configuracion de HardHat cuando aplica;
- contexto operativo (`TTY`, privilegios/sudo).

Salida:
- humana por defecto con resumen, estado por check, notas y recomendaciones;
- JSON con envoltura consistente (`metadata`, `command`, `status`, `summary`, `notes`) y seccion `checks`.

Comportamiento de salida con `--json`:
- `stdout` contiene solo JSON valido.
- diagnosticos operativos quedan en `stderr`.

Notas:
- `doctor` no modifica estado del sistema;
- si el entorno no es compatible o faltan componentes, reporta warning con recomendaciones accionables.

### `hardhat firewall audit`

Audita especificamente UFW:
- instalado o no;
- backend esperado y backend ausente/presente;
- activo/inactivo/desconocido;
- politica por defecto cuando se puede;
- reglas parseadas cuando se puede;
- deteccion de configuraciones debiles;
- recomendaciones.

Salida:
- humana por defecto;
- JSON con metadatos, seccion firewall, estado de backend, resumen, notas, hallazgos y recomendaciones.

Comportamiento de salida con `--json`:
- `stdout` contiene solo JSON valido.
- no se imprime banner ASCII ni logs informativos `[INFO]`.
- advertencias o errores relevantes pueden emitirse por `stderr`.

Si UFW no esta instalado:
- HardHat informa que no hay firewall soportado/configurado para este MVP.
- HardHat marca esta condicion como riesgo por aumento de exposicion.
- HardHat recomienda instalar y configurar UFW con `hardhat firewall apply`.

### `hardhat firewall apply`

Aplica linea base segura de UFW con flujo guiado y seguro:
1. valida entorno y compatibilidad;
2. audita estado actual;
3. si UFW no esta instalado, informa riesgo y ofrece instalarlo con pacman;
4. construye y muestra plan;
5. en `--dry-run` no modifica nada;
    en este modo no requiere sudo/root para simular el flujo.
6. pide confirmacion explicita (o usa `--yes`);
7. si hace falta, instala UFW con pacman;
8. aplica politica de respaldo segun contexto (ver notas de seguridad);
9. aplica politicas de linea base;
10. valida estado final;
11. registra evento de aplicacion en log.

Comportamiento de salida con `--json` en `firewall apply`:
- `stdout` contiene solo un JSON final valido con resumen de ejecucion.
- `stderr` conserva advertencias/errores operativos del flujo.
- El JSON incluye `metadata`, `command`, `status`, `apply`, `firewall`, `summary`, `notes` y `recommendations`.

Politica de linea base:
- `deny incoming`
- `allow outgoing`

Si `sshd` esta activo, intenta detectar puerto SSH y agrega regla de permiso cuando hace falta para reducir riesgo de bloqueo de acceso.

Cuando UFW no esta instalado:
- HardHat avisa que no hay firewall soportado para el MVP.
- HardHat indica que el sistema puede estar expuesto sin linea base.
- HardHat ofrece instalar UFW y continuar con la configuracion segura.

Notas de seguridad para respaldo en `firewall apply`:
- Caso A (UFW preexistente): respaldo obligatorio de configuracion existente antes de aplicar cambios.
- Caso B (instalacion nueva de UFW): si aun no existen archivos de configuracion, HardHat no bloquea por respaldo imposible; si existen archivos tras instalar, los respalda antes de modificar.
- Si existe configuracion y el respaldo falla, HardHat aborta.
- No hay reversion automatica en el MVP.

## Instalacion en Arch Linux

HardHat mantiene enfoque Arch-first. Hoy hay dos rutas validas:
- instalacion manual con `install.sh` (util durante desarrollo local);
- instalacion empaquetada con `makepkg` + `pacman` (recomendada para flujo Arch).

### Opcion A: instalacion manual (desarrollo/local)

Instalacion manual recomendada:

```bash
cd HardHat
./install.sh
```

Durante la instalacion se solicita idioma preferido de la app.
Idiomas disponibles en esta fase: `en` y `es`.

Simulacion de instalacion:

```bash
./install.sh --dry-run --yes
```

Instalacion no interactiva:

```bash
./install.sh --yes
```

Instalacion no interactiva con idioma explicito:

```bash
./install.sh --yes --lang es
```

El instalador manual:
- valida estructura runtime (`bin/`, `lib/`, `modules/`);
- muestra plan de instalacion;
- pide confirmacion (salvo `--yes`);
- copia runtime a `/opt/hardhat`;
- crea enlace en `/usr/local/bin/hardhat`.
- guarda idioma global en `/etc/hardhat/config`.
- guarda idioma del usuario actual en `~/.config/hardhat/config`.

### Opcion B: paquete Arch con PKGBUILD (makepkg)

El repositorio incluye un `PKGBUILD` simple para empaquetado en Arch sin usar el instalador manual dentro del paquete.

Flujo recomendado de construccion:

```bash
makepkg --printsrcinfo > .SRCINFO
makepkg -f
```

Dependencias tipicas para construir paquete en Arch:

```bash
sudo pacman -S --needed base-devel
```

Instalacion del paquete generado:

```bash
sudo pacman -U ./hardhat-*.pkg.tar.*
```

Prueba basica despues de instalar paquete:

```bash
hardhat --version
hardhat help
hardhat audit
hardhat --json firewall apply --dry-run --yes
```

Desinstalacion recomendada para instalacion empaquetada:

```bash
sudo pacman -R hardhat
```

Que instala el paquete:
- runtime en `/opt/hardhat` (con `bin/`, `lib/`, `modules/`, `accsi.txt`);
- comando gestionado por paquete en `/usr/bin/hardhat` (symlink a `/opt/hardhat/bin/hardhat`);
- documentacion en `/usr/share/doc/hardhat`.

Notas importantes:
- para instalacion empaquetada en Arch, se recomienda `pacman -S/-U` y desinstalar con `pacman -R hardhat`;
- `install.sh` y `hardhat uninstall` siguen siendo validos como alternativa para instalaciones manuales fuera de flujo de paquete;
- si usas `hardhat uninstall` sobre instalacion empaquetada, ajusta rutas explicitamente (por ejemplo `--bin-dir /usr/bin`) o usa preferentemente pacman para evitar inconsistencias.
- el `PKGBUILD` actual esta orientado a empaquetado local desde este checkout (desarrollo); para un release formal faltaria fijar `source` versionado y checksums del tarball de release.

## Release readiness (Arch-first)

Politica y checklist minimo de release:

```bash
docs/RELEASE_POLICY.md
docs/RELEASE_CHECKLIST.md
```

El objetivo es asegurar coherencia entre estabilidad CLI/JSON, versionado, PKGBUILD/.SRCINFO, tests y validacion de instalacion/desinstalacion con `pacman`.

## Configurar idioma despues de instalar

Ver idioma actual:

```bash
hardhat language show
```

Cambiar idioma para tu usuario:

```bash
hardhat language set es
hardhat language set en
```

La preferencia de usuario se guarda en `~/.config/hardhat/config` y tiene prioridad sobre la configuracion global.

## Desinstalacion

Desinstalacion recomendada (via CLI):

```bash
hardhat uninstall
```

Desinstalacion no interactiva:

```bash
hardhat uninstall --yes
```

Simulacion de desinstalacion:

```bash
hardhat uninstall --dry-run --yes
```

Salida JSON de desinstalacion:

```bash
hardhat --json uninstall --dry-run --yes
```

En modo JSON, `uninstall` entrega contrato minimo consistente en `stdout` (`metadata`, `command`, `status`, `summary`, `notes`) y usa `stderr` para diagnosticos.

Eliminar tambien configuracion global y de usuario:

```bash
hardhat uninstall --yes --purge-config
```

Nota:
- Por seguridad, el desinstalador solo elimina `/usr/local/bin/hardhat` si apunta al runtime de HardHat esperado.
- `uninstall.sh` se mantiene como wrapper temporal/deprecado para compatibilidad.

Opciones de `hardhat uninstall`:

```bash
--yes
--dry-run
--purge-config
--install-root <path>
--bin-dir <path>
--lang <en|es>
```

## Troubleshooting rapido

Guia corta para incidencias frecuentes:
- `hardhat menu` sin TTY: falla por diseno en stdin/stdout no interactivos; usa comandos directos o abre una terminal interactiva.
- sudo/root ausente en acciones privilegiadas: ejecuta en `--dry-run` para validar plan y luego repite con root/sudo disponible.
- UFW no instalado: usa `hardhat firewall apply` para flujo guiado de instalacion/configuracion en Arch.
- salida JSON inesperada: en `--json`, espera JSON en stdout y mensajes operativos en stderr.
- instalacion/desinstalacion parcial: reintenta con `--dry-run` primero para validar rutas/plan y luego ejecuta el flujo real.

Documentacion detallada:
- `docs/TROUBLESHOOTING.md`

## Estructura actual del proyecto

```text
.
├── bin/
│   └── hardhat
├── docs/
│   ├── ARCHITECTURE.md
│   ├── MVP.md
│   ├── RELEASE_POLICY.md
│   ├── RELEASE_CHECKLIST.md
│   ├── TROUBLESHOOTING.md
│   └── TODO.md
├── install.sh
├── PKGBUILD
├── uninstall.sh
├── lib/
│   ├── backup.sh
│   ├── colors.sh
│   ├── common.sh
│   ├── confirm.sh
│   ├── detect.sh
│   ├── json.sh
│   ├── log.sh
│   ├── privileges.sh
│   ├── sudo.sh
│   └── validate.sh
├── modules/
│   ├── audit.sh
│   ├── firewall.sh
│   ├── ports.sh
│   ├── services.sh
│   ├── ssh_audit.sh
│   └── updates.sh
├── tests/
│   ├── help_usage_smoke.sh
│   ├── cli_edge_cases_smoke.sh
│   ├── doctor_smoke.sh
│   ├── smoke_core_commands.sh
│   ├── uninstall_subcommand_smoke.sh
│   ├── integration_safe_cli.sh
│   ├── unit_helpers.sh
│   ├── run_all.sh
│   └── run_tests.sh
├── .editorconfig
├── .gitignore
├── README.md
├── shellcheckrc
└── shfmt.conf
```

## Calidad y estilo

Checks recomendados:

```bash
bash -n bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh
shellcheck -x bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh
shfmt -i 2 -ci -sr -bn -d bin/hardhat install.sh uninstall.sh lib/*.sh modules/*.sh
```

Smoke test sugerido para uninstall:

```bash
hardhat uninstall --dry-run --yes --install-root /tmp/hh-test/root --bin-dir /tmp/hh-test/bin --purge-config
```

## Tests (estrategia inicial)

HardHat mantiene una estrategia simple, sin framework externo:
- smoke CLI: validacion rapida de ayuda/uso y rutas criticas seguras;
- integracion segura: flujos reales del CLI priorizando `--dry-run` y JSON;
- unitarios shell: helpers deterministas de `lib/`.

Estructura actual:

```bash
tests/help_usage_smoke.sh
tests/cli_edge_cases_smoke.sh
tests/smoke_core_commands.sh
tests/uninstall_subcommand_smoke.sh
tests/integration_safe_cli.sh
tests/unit_helpers.sh
tests/run_all.sh
tests/run_tests.sh
```

Cobertura principal:
- help/usage global y por comando (`help`, `--help`, `help firewall`, `help firewall apply`, `help menu`, `menu --help`);
- escenarios de borde de UX/CLI: flags invalidas, subayudas, menu sin TTY, menu incompatible con `--json`;
- `uninstall --dry-run --yes` con rutas temporales;
- `doctor` (help, salida humana y salida JSON parseable);
- combinaciones seguras de `uninstall` (incluyendo cancelacion y errores de uso en JSON/no-JSON);
- `firewall apply --dry-run --yes`;
- variantes de `firewall apply --dry-run` (JSON, argumentos invalidos y estructura de estado);
- salida JSON basica en `audit --json`, `firewall audit --json`, `firewall apply --dry-run --yes --json`;
- salida JSON basica en `uninstall --dry-run --yes --json`;
- unit tests para helpers deterministas (`hardhat_trim`, validadores y join simple).

Contrato de exit codes (MVP):
- `0`: exito
- `2`: error de uso/argumentos
- `10`: warning parcial
- `20`: error operativo
- `30`: cancelacion/abort por usuario

Ejecucion:

```bash
# Todo
bash tests/run_all.sh
bash tests/run_all.sh smoke
bash tests/run_all.sh integration
bash tests/run_all.sh unit

# Compatibilidad (wrapper)
bash tests/run_tests.sh

# Por tipo
bash tests/run_tests.sh smoke
bash tests/run_tests.sh integration
bash tests/run_tests.sh unit

# Scripts individuales
bash tests/help_usage_smoke.sh
bash tests/cli_edge_cases_smoke.sh
bash tests/smoke_core_commands.sh
bash tests/uninstall_subcommand_smoke.sh
bash tests/integration_safe_cli.sh
bash tests/unit_helpers.sh
```

Notas:
- La mayoria de pruebas evita cambios reales del sistema y prioriza `--dry-run`.
- Algunas rutas operativas dependen de entorno Arch Linux; los tests de integracion segura pueden auto-saltarse fuera de Arch.
- `tests/smoke_core_commands.sh` valida comandos core + contrato JSON/exit codes base.
- `tests/cli_edge_cases_smoke.sh` valida comportamiento observable de UX: ayudas/subayudas, flags invalidas, cancelaciones seguras, menu sin TTY y separacion stdout/stderr en modo JSON.

Nota:
- `shellcheck` y `shfmt` no son dependencias runtime de HardHat.

## Documentacion complementaria

- `docs/MVP.md`: alcance y estado del MVP.
- `docs/ARCHITECTURE.md`: arquitectura y flujo tecnico.
- `docs/RELEASE_POLICY.md`: criterio minimo de estabilidad, compatibilidad CLI/JSON y alcance oficial.
- `docs/RELEASE_CHECKLIST.md`: checklist minimo para primera release Arch-first.
- `docs/TROUBLESHOOTING.md`: troubleshooting operativo y permisos.
- `docs/TODO.md`: pendientes priorizados de implementacion.


## Licencia

Este proyecto se distribuye bajo la licencia MIT.
