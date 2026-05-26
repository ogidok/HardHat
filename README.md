
```
    )                      )              
 ( /(              (    ( /(           )  
 )\())    )  (     )\ ) )\())    )  ( /(  
((_)\  ( /(  )(   (()/(((_)\  ( /(  )\()) 
 _((_) )(_))(()\   ((_))_((_) )(_))(_))/  
| || |((_)_  ((_)  _| || || |((_)_ | |_   
| __ |/ _` || '_|/ _` || __ |/ _` ||  _|  
|_||_|\__,_||_|  \__,_||_||_|\__,_| \__|  
                                         
```


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
- El JSON incluye `metadata`, `apply`, `firewall`, `summary`, `notes` y `recommendations`.

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

## Instalacion

Instalacion recomendada:

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

El instalador:
- valida estructura runtime (`bin/`, `lib/`, `modules/`);
- muestra plan de instalacion;
- pide confirmacion (salvo `--yes`);
- copia runtime a `/opt/hardhat`;
- crea enlace en `/usr/local/bin/hardhat`.
- guarda idioma global en `/etc/hardhat/config`.
- guarda idioma del usuario actual en `~/.config/hardhat/config`.

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

## Estructura actual del proyecto

```text
.
├── bin/
│   └── hardhat
├── docs/
│   ├── ARCHITECTURE.md
│   ├── MVP.md
│   └── TODO.md
├── install.sh
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

## Tests (estructura base)

```bash
tests/help_usage_smoke.sh
tests/uninstall_subcommand_smoke.sh
```

Cobertura principal actual de smoke:
- ayudas globales y por subcomando (`help`, `--help`, `help firewall`, `help firewall apply`, `help menu`, `menu --help`);
- errores de uso para argumentos invalidos en comandos principales;
- validacion de restricciones de `menu` en modo no interactivo (TTY);
- flujo seguro de `uninstall` en `--dry-run`.

Ejecutar:

```bash
bash tests/help_usage_smoke.sh
bash tests/uninstall_subcommand_smoke.sh
```

Nota:
- `shellcheck` y `shfmt` no son dependencias runtime de HardHat.

## Documentacion complementaria

- `docs/MVP.md`: alcance y estado del MVP.
- `docs/ARCHITECTURE.md`: arquitectura y flujo tecnico.
- `docs/TODO.md`: pendientes priorizados de implementacion.


## Licencia

Este proyecto se distribuye bajo la licencia MIT.