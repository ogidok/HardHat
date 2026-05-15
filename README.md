
```
    )                      )              
 ( /(              (    ( /(           )  
 )\())    )  (     )\ ) )\())    )  ( /(  
((_)\  ( /(  )(   (()/(((_)\  ( /(  )\()) 
 _((_) )(_))(()\   ((_))_((_) )(_))(_))/  
| || |((_)_  ((_)  _| || || |((_)_ | |_   
| __ |/ _` || '_|/ _` || __ |/ _` ||  _|  
|_||_|\__,_||_|  \__,_||_||_|\__,_| \__|  
                                         v1
```


# HardHat

HardHat es una herramienta CLI para Arch Linux, escrita en Bash, enfocada en auditoria basica de seguridad y aplicacion guiada de cambios de firewall.

## Estado del proyecto

MVP/preview funcional. Lo implementado ya se puede usar desde linea de comandos para validacion tecnica y pruebas controladas.

Importante:
- no hay rollback automatico;
- si se aplican cambios, la restauracion es manual con backups;
- si no se pueden crear backups, no se aplican cambios.

## Compatibilidad oficial del MVP

- Arch Linux
- backend de firewall: UFW

En el futuro puede evaluarse soporte para otras distribuciones, pero el MVP actual solo soporta Arch Linux.

## Comandos disponibles

```bash
hardhat help
hardhat version
hardhat audit
hardhat audit --json
hardhat firewall audit
hardhat firewall audit --json
hardhat firewall apply
hardhat firewall apply --dry-run
hardhat menu
```

Notas:
- `hardhat menu` existe como stub limpio (aun no implementado).
- Las flags globales pueden ir antes o despues del comando.

## Flags globales disponibles

```bash
--dry-run
--yes
--json
--verbose
--no-color
--help
--version
```

## Que hace hoy el MVP

### `hardhat audit`

Ejecuta una auditoria baseline y devuelve:
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

Aplica baseline segura de UFW con flujo guiado y seguro:
1. valida entorno y compatibilidad;
2. audita estado actual;
3. si UFW no esta instalado, informa riesgo y ofrece instalarlo con pacman;
4. construye y muestra plan;
5. en `--dry-run` no modifica nada;
6. pide confirmacion explicita (o usa `--yes`);
7. si hace falta, instala UFW con pacman;
8. aplica politica de backup segun contexto (ver notas de seguridad);
9. aplica politicas baseline;
10. valida estado final;
11. registra evento de aplicacion en log.

Politica baseline:
- `deny incoming`
- `allow outgoing`

Si `sshd` esta activo, intenta detectar puerto SSH y agrega regla allow cuando hace falta para reducir riesgo de lockout.

Cuando UFW no esta instalado:
- HardHat avisa que no hay firewall soportado para el MVP.
- HardHat indica que el sistema puede estar expuesto sin baseline.
- HardHat ofrece instalar UFW y continuar con la configuracion segura.

Notas de seguridad para backup en `firewall apply`:
- Caso A (UFW preexistente): backup obligatorio de configuracion existente antes de aplicar cambios.
- Caso B (instalacion nueva de UFW): si aun no existen archivos de configuracion, HardHat no bloquea por backup imposible; si existen archivos tras instalar, los respalda antes de modificar.
- Si existe configuracion y el backup falla, HardHat aborta.
- No hay rollback automatico en el MVP.

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

Desinstalacion recomendada:

```bash
./uninstall.sh
```

Desinstalacion no interactiva:

```bash
./uninstall.sh --yes
```

Simulacion de desinstalacion:

```bash
./uninstall.sh --dry-run --yes
```

Eliminar tambien configuracion global (`/etc/hardhat/config`):

```bash
./uninstall.sh --yes --purge-config
```

Nota:
- Por seguridad, el desinstalador solo elimina `/usr/local/bin/hardhat` si apunta al runtime de HardHat esperado.

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

Nota:
- `shellcheck` y `shfmt` no son dependencias runtime de HardHat.

## Documentacion complementaria

- `docs/MVP.md`: alcance y estado del MVP.
- `docs/ARCHITECTURE.md`: arquitectura y flujo tecnico.
- `docs/TODO.md`: pendientes priorizados de implementacion.


## Licencia

Este proyecto se distribuye bajo la licencia MIT.