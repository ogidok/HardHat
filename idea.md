# HardHat — Linux Security Bootstrapper

## Idea General

HardHat es un proyecto pensado para usuarios de Linux —especialmente quienes migran desde distribuciones más simples como Ubuntu hacia sistemas más manuales como Arch Linux— que terminan utilizando sistemas potencialmente inseguros por falta de configuración inicial.

La idea principal es crear una herramienta que automatice:

* Auditorías básicas y avanzadas de seguridad.
* Hardening inicial del sistema.
* Configuración de firewall.
* Revisión de servicios inseguros.
* Recomendaciones contextualizadas.
* Ajustes para distintos perfiles de usuario.
* Reportes claros y entendibles.

El proyecto busca ser:

* Transparente.
* Modular.
* Interactivo.
* Seguro.
* Fácil de ejecutar.
* Compatible con múltiples distribuciones Linux.

---

# Problema que busca resolver

Muchos usuarios:

* Instalan Arch Linux u otras distros minimalistas.
* Configuran solo lo necesario para usar el sistema.
* No revisan:

  * permisos,
  * servicios expuestos,
  * puertos abiertos,
  * configuraciones vulnerables,
  * reglas de firewall,
  * sysctl,
  * SSH,
  * políticas de red,
  * logs,
  * hardening básico.

Eso deja sistemas relativamente vulnerables.

HardHat busca actuar como una especie de:

> “bootstrapper de seguridad y auditoría para Linux”.

---

# Objetivo del proyecto

Crear un script/herramienta que:

1. Audite el sistema.
2. Detecte configuraciones débiles.
3. Sugiera mejoras.
4. Automatice configuraciones seguras.
5. Permita al usuario decidir qué cambios aplicar.
6. Explique claramente cada modificación.
7. Sea útil tanto para usuarios normales como desarrolladores o estudiantes de ciberseguridad.

---

# Lenguaje y arquitectura

## Decisión inicial

Se decidió comenzar usando Bash.

### Razones

* Bash viene instalado prácticamente en cualquier Linux.
* No requiere entornos virtuales.
* Menos dependencias.
* Mejor portabilidad.
* Fácil integración con herramientas del sistema.
* Más simple para distribución inicial.

A futuro:

* Algunas partes complejas podrían migrarse a Python.
* Posible arquitectura híbrida Bash + Python.
* Eventualmente empaquetarlo como binario.

---

# Filosofía de funcionamiento

HardHat NO debería:

* cambiar configuraciones silenciosamente;
* romper setups existentes;
* asumir configuraciones;
* ocultar comandos ejecutados.

HardHat SÍ debería:

* mostrar exactamente qué hace;
* pedir confirmación;
* detectar configuraciones ya existentes;
* comparar configuración actual vs propuesta;
* permitir conservar configuraciones personalizadas;
* generar backups automáticos;
* ofrecer rollback cuando sea posible.

---

# Funcionalidades iniciales (MVP)

## 1. Auditoría del sistema

Revisar:

* usuarios;
* permisos inseguros;
* servicios activos;
* puertos abiertos;
* sudoers;
* configuración SSH;
* kernel parameters;
* procesos sospechosos;
* servicios innecesarios;
* configuraciones débiles;
* paquetes inseguros o desactualizados.

---

## 2. Firewall

Automatizar configuración básica de:

* UFW;
* nftables;
* iptables.

El usuario puede elegir.

Ejemplo:

* bloquear tráfico entrante;
* permitir tráfico saliente;
* abrir puertos específicos;
* proteger SSH;
* perfiles preconfigurados.

---

## 3. Hardening

Aplicar configuraciones seguras para:

* sysctl;
* SSH;
* permisos;
* servicios;
* networking;
* DNS;
* logs;
* privacidad.

---

## 4. Escaneo de vulnerabilidades

Se descartó usar únicamente Nmap porque es demasiado básico para el objetivo.

La idea es integrar herramientas más avanzadas capaces de:

* detectar vulnerabilidades locales;
* analizar configuraciones inseguras;
* revisar CVEs;
* detectar malas prácticas.

Posibles herramientas futuras:

* Lynis;
* OpenVAS;
* OpenSCAP;
* chkrootkit;
* rkhunter.

---

## 5. Perfil del usuario

El script podría ofrecer perfiles como:

### Usuario normal

Configuración segura sin romper compatibilidad.

### Desarrollador

Mantener herramientas necesarias:

* Docker;
* SSH;
* puertos locales;
* entornos de desarrollo.

### Estudiante de ciberseguridad

Más flexibilidad:

* herramientas ofensivas;
* networking avanzado;
* laboratorios;
* monitoreo.

---

# Interfaz esperada

## CLI interactiva

Ejemplo conceptual:

```bash
[+] Detectado SSH activo
[!] Permitido login por contraseña

Recomendación:
- Deshabilitar password login
- Usar únicamente llaves SSH

¿Aplicar cambio?
[y/N]
```

---

# Características importantes

## Transparencia

Siempre mostrar:

* qué archivo se modifica;
* qué línea cambia;
* por qué;
* impacto potencial.

---

## Seguridad

* Crear backups automáticos.
* Evitar configuraciones destructivas.
* Validar antes de aplicar.
* Modo simulación (`--dry-run`).

---

## Modularidad

Cada módulo separado:

* firewall;
* SSH;
* kernel;
* auditoría;
* networking;
* hardening.

Ejemplo:

```bash
hardhat firewall
hardhat audit
hardhat ssh
hardhat dev-profile
```

---

# Público objetivo

* Usuarios nuevos de Arch Linux.
* Usuarios intermedios.
* Estudiantes de ciberseguridad.
* Desarrolladores.
* Personas que quieren asegurar rápidamente un Linux recién instalado.

---

# Diferenciador principal

No ser solamente:

* un escáner,
* ni solo un hardener,
* ni solo un instalador.

Sino una herramienta que:

* explique,
* enseñe,
* automatice,
* y permita control total.

---

# Nombre del proyecto

## HardHat

Inspiración:

* casco de seguridad;
* protección;
* preparación;
* herramienta para trabajar de forma segura.

Posible tagline:

> HardHat — Linux Security Bootstrapper

O:

> HardHat — Secure your Linux before it becomes a problem.

---

# Ideas futuras

## Dashboard TUI

Interfaz estilo terminal usando:

* gum;
* dialog;
* whiptail;
* curses.

---

## Reportes HTML

Generar:

* resumen de seguridad;
* score;
* recomendaciones;
* cambios aplicados.

---

## Integración con GitHub

* repositorio de reglas;
* perfiles compartidos;
* actualizaciones.

---

## Sistema de plugins

Permitir módulos externos:

```bash
hardhat plugins install docker-security
```

---

# Roadmap inicial sugerido

## Fase 1

* CLI básica.
* Logs.
* Detección de distro.
* Auditoría inicial.
* Firewall básico.
* Backups.

## Fase 2

* Hardening SSH.
* sysctl.
* Servicios.
* Perfiles de usuario.
* Reportes.

## Fase 3

* Vulnerability scanning.
* TUI.
* Plugins.
* Multi-distro avanzado.
* Binarios.

---

# Idea central resumida

HardHat busca convertirse en:

> “La herramienta que prepara y asegura un Linux recién instalado sin obligar al usuario a conocer todos los detalles técnicos desde el primer día.”
