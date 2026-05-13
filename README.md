# HardHat

HardHat es una herramienta CLI para Arch Linux, escrita en Bash, enfocada en auditoria basica de seguridad y aplicacion guiada de cambios seguros de firewall.

## Estado del proyecto

MVP funcional en progreso. Lo implementado ya se puede usar desde linea de comandos.

Importante:
- no hay rollback automatico;
- si se aplican cambios, la restauracion es manual con backups;
- si no se pueden crear backups, no se aplican cambios.

## Compatibilidad oficial del MVP

- Arch Linux
- backend de firewall: UFW

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

### `hardhat firewall audit`

Audita especificamente UFW:
- instalado o no;
- activo/inactivo/desconocido;
- politica por defecto cuando se puede;
- reglas parseadas cuando se puede;
- deteccion de configuraciones debiles;
- recomendaciones.

Salida:
- humana por defecto;
- JSON con metadatos, seccion firewall, resumen, notas, hallazgos y recomendaciones.

### `hardhat firewall apply`

Aplica baseline segura de UFW con flujo controlado:
1. valida entorno y compatibilidad;
2. audita estado actual;
3. construye y muestra plan;
4. en `--dry-run` no modifica nada;
5. crea backups obligatorios;
6. pide confirmacion global (o usa `--yes`);
7. aplica politicas baseline;
8. valida estado final;
9. registra evento de aplicacion en log.

Politica baseline:
- `deny incoming`
- `allow outgoing`

Si `sshd` esta activo, intenta detectar puerto SSH y agrega regla allow cuando hace falta para reducir riesgo de lockout.

## Instalacion

Instalacion recomendada:

```bash
cd HardHat
./installers/install.sh
```

Simulacion de instalacion:

```bash
./installers/install.sh --dry-run --yes
```

Instalacion no interactiva:

```bash
./installers/install.sh --yes
```

El instalador:
- valida estructura runtime (`bin/`, `lib/`, `modules/`);
- muestra plan de instalacion;
- pide confirmacion (salvo `--yes`);
- copia runtime a `/opt/hardhat`;
- crea enlace en `/usr/local/bin/hardhat`.

## Desinstalacion manual

```bash
sudo rm -f /usr/local/bin/hardhat
sudo rm -rf /opt/hardhat
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
├── installers/
│   └── install.sh
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
bash -n bin/hardhat installers/install.sh lib/*.sh modules/*.sh
shellcheck -x bin/hardhat installers/install.sh lib/*.sh modules/*.sh
shfmt -i 2 -ci -sr -bn -d bin/hardhat installers/install.sh lib/*.sh modules/*.sh
```

Nota:
- `shellcheck` y `shfmt` no son dependencias runtime de HardHat.

## Documentacion complementaria

- `docs/MVP.md`: alcance y estado del MVP.
- `docs/ARCHITECTURE.md`: arquitectura y flujo tecnico.
- `docs/TODO.md`: pendientes priorizados de implementacion.