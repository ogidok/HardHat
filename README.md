# HardHat

```text
           )                      )              
        ( /(              (    ( /(           )  
        )\())    )  (     )\ ) )\())    )  ( /(  
        ((_)\  ( /(  )(   (()/(((_)\  ( /(  )\()) 
        _((_) )(_))(()\   ((_))_((_) )(_))(_))/  
        | || |((_)_  ((_)  _| || || |((_)_ | |_   
        | __ |/ _` || '_|/ _` || __ |/ _` ||  _|  
        |_||_|\__,_||_|  \__,_||_||_|\__,_| \__|  
                                          
```

> HardHat — Linux Security Bootstrapper for Arch Linux

HardHat es una herramienta CLI enfocada en **Arch Linux** para auditar el estado básico de seguridad del sistema, detectar configuraciones inseguras, sugerir mejoras y aplicar cambios de forma guiada y segura.

El objetivo del proyecto es ayudar a usuarios que quieren asegurar una instalación reciente de Linux sin tener que conocer desde el primer momento todos los detalles técnicos de hardening.

---

# Estado del proyecto

**HardHat está en fase temprana de diseño y construcción.**

La primera versión estará enfocada en:

- auditoría básica de seguridad;
- revisión de firewall;
- revisión de puertos abiertos;
- revisión de servicios relevantes;
- detección de configuraciones inseguras;
- sugerencias claras de remediación;
- aplicación guiada de reglas básicas de firewall;
- logs;
- soporte para `--dry-run`;
- backups automáticos antes de modificar.

> **Importante:** en la primera versión **no habrá rollback automático**.  
> Si se aplica un cambio, la restauración deberá hacerse manualmente usando los backups generados.

---

# Objetivo

HardHat busca ser una herramienta que:

- audite;
- explique;
- recomiende;
- y automatice con control.

No quiere ser solamente:

- un escáner,
- ni solo un hardener,
- ni solo un script de instalación.

La idea es ofrecer una base de seguridad razonable para Arch Linux con una experiencia clara, entendible y segura.

---

# Filosofía del proyecto

HardHat **no debe**:

- cambiar configuraciones silenciosamente;
- romper setups existentes de forma innecesaria;
- asumir configuraciones sin validación;
- ocultar qué comandos ejecuta.

HardHat **sí debe**:

- mostrar qué detectó;
- explicar por qué algo es riesgoso;
- sugerir cambios concretos;
- pedir confirmación antes de aplicar;
- crear backups antes de modificar;
- bloquear cambios si no puede respaldar;
- permitir simulación con `--dry-run`;
- priorizar seguridad sobre comodidad.

---

# Alcance del MVP

La primera versión estará enfocada en **Arch Linux** y en un conjunto de funcionalidades pequeño, claro y estable.

## Incluye

- soporte inicial para **Arch Linux**;
- implementación en **Bash modular**;
- comando principal de auditoría;
- score o resumen general de riesgo;
- clasificación de hallazgos por severidad;
- revisión de firewall;
- revisión de puertos abiertos;
- revisión de servicios activos relevantes;
- detección de configuraciones inseguras;
- revisión básica de configuración SSH como parte de la auditoría;
- detección de actualizaciones pendientes como señal de riesgo;
- salida humana y JSON;
- colores, símbolos y logs claros;
- backups automáticos antes de cambios;
- soporte de `--dry-run`;
- aplicación guiada de reglas básicas de firewall.

## No incluye todavía

- multi-distro;
- nftables;
- iptables;
- rollback automático;
- TUI avanzada;
- plugins;
- reportes HTML;
- escaneo profundo de CVEs;
- integración con herramientas pesadas como OpenVAS/OpenSCAP;
- hardening avanzado completo de SSH;
- tests desde el primer día.

---

# Qué entiende HardHat por “vulnerabilidades” en la v0.1

En el MVP, HardHat tratará “vulnerabilidades” como:

1. **configuraciones inseguras**
   - firewall desactivado;
   - puertos expuestos;
   - servicios sensibles activos;
   - opciones SSH inseguras;
   - políticas débiles.

2. **señales de riesgo del estado del sistema**
   - actualizaciones pendientes;
   - exposición innecesaria;
   - configuraciones no recomendadas.

> HardHat no realizará en esta etapa un escaneo profundo de CVEs ni reemplazará herramientas especializadas de auditoría avanzada.

---

# Funcionalidades planeadas

## 1. Auditoría general

El comando principal será:

```bash
hardhat audit
```

Debe mostrar:

- resumen general;
- score;
- hallazgos;
- severidad;
- recomendaciones;
- estado del firewall;
- puertos en escucha;
- servicios relevantes;
- señales de configuración insegura;
- salida opcional en JSON.

## 2. Firewall

Backend inicial soportado:

- **UFW**

Comandos previstos:

```bash
hardhat firewall audit
hardhat firewall apply
hardhat firewall apply --dry-run
```

Capacidades esperadas:

- detectar si UFW está instalado;
- revisar si está activo;
- revisar políticas por defecto;
- revisar reglas existentes;
- sugerir configuración básica segura;
- aplicar cambios tras confirmación.

### Política base recomendada

- `deny incoming`
- `allow outgoing`

## 3. Revisión básica de SSH

SSH no será todavía un módulo autónomo complejo, pero sí se revisará dentro de la auditoría general.

Checks previstos:

- si `sshd` está activo;
- si hay configuración riesgosa;
- estado de `PasswordAuthentication`;
- estado de `PermitRootLogin`;
- puerto configurado, cuando sea posible detectarlo.

## 4. Servicios, puertos y estado general

La auditoría inicial también revisará:

- puertos en escucha;
- servicios activos relevantes;
- servicios habilitados relevantes;
- exposición básica del sistema;
- actualizaciones pendientes como indicador de riesgo.

---

# Seguridad operacional

## Confirmación antes de aplicar cambios

HardHat mostrará primero un plan de cambios y luego pedirá una **confirmación global** antes de aplicar.

## Backups automáticos

Antes de modificar configuraciones, HardHat deberá:

- generar backup;
- validar que el backup existe;
- bloquear cambios si no pudo respaldar.

## Rollback

Por ahora:

- **no habrá rollback automático**;
- la recuperación será **manual**;
- esto debe quedar siempre claro para el usuario.

---

# Experiencia de uso

HardHat tendrá dos formas de uso:

## 1. CLI por subcomandos

Pensada para usuarios más cómodos con terminal:

```bash
hardhat audit
hardhat firewall audit
hardhat firewall apply
```

## 2. Menú interactivo

Pensado para usuarios menos experimentados:

```bash
hardhat menu
```

El modo interactivo **no será el modo por defecto**.

---

# Flags previstas

Las flags iniciales recomendadas son:

```bash
--dry-run
--yes
--json
--verbose
--no-color
--help
--version
```

### Descripción rápida

- `--dry-run`: muestra qué haría sin modificar nada.
- `--yes`: acepta la confirmación global.
- `--json`: salida estructurada para scripts o integración.
- `--verbose`: logs detallados.
- `--no-color`: desactiva colores.
- `--help`: ayuda.
- `--version`: versión actual.

---

# Salida JSON

HardHat ofrecerá salida en formato humano por defecto, pero también salida estructurada para automatización.

Ejemplos previstos:

```bash
hardhat audit --json
hardhat firewall audit --json
```

---

# Compatibilidad

## Compatibilidad inicial oficial

- **Arch Linux**

El proyecto se diseñará primero para ser estable y consistente en Arch antes de considerar soporte para otras distribuciones.

---

# Instalación

La experiencia deseada es poder ejecutar:

```bash
hardhat
```

y no depender de:

```bash
./hardhat
```

La estrategia inicial de instalación será:

1. script de instalación (`install.sh`);
2. más adelante, posible `PKGBUILD` para Arch.

> La instalación definitiva puede cambiar a medida que avance el proyecto.

---

# Estructura sugerida del proyecto

```text
HardHat/
├── bin/
│   └── hardhat
├── lib/
│   ├── common.sh
│   ├── log.sh
│   ├── colors.sh
│   ├── sudo.sh
│   ├── json.sh
│   ├── backup.sh
│   ├── confirm.sh
│   ├── detect.sh
│   └── validate.sh
├── modules/
│   ├── audit.sh
│   ├── firewall.sh
│   ├── ssh_audit.sh
│   ├── services.sh
│   ├── ports.sh
│   └── updates.sh
├── installers/
│   └── install.sh
├── docs/
│   ├── MVP.md
│   └── ARCHITECTURE.md
├── examples/
│   └── hardhat-output.json
├── README.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── shellcheckrc
└── shfmt.conf
```

---

# Calidad del proyecto

Desde el inicio, HardHat buscará mantener:

- código Bash modular y mantenible;
- baja dependencia de herramientas externas;
- facilidad de instalación;
- claridad operativa;
- compatibilidad fuerte con Arch Linux;
- validación y backups antes de cambiar el sistema.

Herramientas de calidad previstas:

- `shellcheck`
- `shfmt`

---

# Roadmap inicial

## Fase 1
- estructura base del proyecto;
- comando principal;
- detección de entorno;
- logs;
- auditoría básica;
- revisión de firewall;
- revisión de puertos;
- score y severidades.

## Fase 2
- aplicación guiada de reglas básicas de UFW;
- backups automáticos;
- dry-run;
- JSON output;
- mejoras de UX.

## Fase 3
- mejoras de auditoría;
- menú interactivo;
- ampliación de checks;
- futura evaluación de soporte a otros backends.

---

# Ejemplos de comandos planeados

```bash
hardhat audit
hardhat audit --json
hardhat firewall audit
hardhat firewall apply
hardhat firewall apply --dry-run
hardhat menu
hardhat help
hardhat version
```

---

# Público objetivo

HardHat está pensado especialmente para:

- usuarios nuevos de Arch Linux;
- usuarios intermedios;
- desarrolladores;
- estudiantes de ciberseguridad;
- personas que quieren asegurar rápido una instalación nueva sin hacerlo todo manualmente.

---

# Estado actual de la visión

La idea central del proyecto es:

> HardHat busca convertirse en una herramienta que prepara y asegura una instalación reciente de Arch Linux sin obligar al usuario a dominar todos los detalles técnicos desde el primer día.

---

# Contribución

Mientras el proyecto madura, la prioridad será:

- definir bien el MVP;
- mantener el alcance controlado;
- construir una base estable y entendible;
- evitar complejidad innecesaria.

---

# Licencia

Pendiente de definir.

---

# Nombre

**HardHat**

Inspirado en:

- protección;
- preparación;
- seguridad;
- herramientas de trabajo seguro.

Tagline actual:

> HardHat — Linux Security Bootstrapper for Arch Linux