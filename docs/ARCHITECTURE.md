# HardHat Architecture (Phase 1)

## Principles
- Keep modules small and focused.
- Prefer explicit command flow over magic.
- Security-first defaults and no silent changes.

## Layout
- `bin/hardhat`: CLI entrypoint, argument parsing, command routing.
- `lib/`: shared helpers (logging, colors, json, backup, confirm, detection).
- `modules/`: domain modules (audit, firewall, ports, services, ssh, updates).
- `installers/`: installation scripts.
- `docs/`: scope and architecture documentation.

## Runtime flow
1. `bin/hardhat` parses global flags.
2. Environment and distro checks run early.
3. Command is dispatched to module function.
4. Module functions call shared helpers from `lib/`.

## Safety model
- `--dry-run` must avoid all write operations.
- Apply flows require explicit global confirmation unless `--yes`.
- Future modifications must create a backup first or abort.# HardHat Architecture (Phase 1)

## Design principles
- Security first.
- No silent changes.
- Small, explicit modules.
- Minimal dependencies.

## Layout
- `bin/`: CLI entrypoint and command dispatch.
- `lib/`: shared utilities (logging, detection, confirmation, backup, validation).
- `modules/`: feature modules (audit, firewall, ssh, ports, services, updates).
- `installers/`: installation scripts.
- `docs/`: technical scope and architecture notes.

## Runtime flow
1. User runs `hardhat`.
2. Entrypoint parses global flags.
3. Distro guard enforces Arch-only MVP scope.
4. Command is dispatched to a module.
5. Modules use `lib/` helpers for output and safety controls.

## Safety scaffolding already present
- Dry-run flag propagated globally.
- Global confirmation helper for future apply flows.
- Backup helper in place to gate future write operations.