# HardHat Architecture

## Current scope
HardHat is an Arch Linux focused Bash CLI for baseline security auditing and guided UFW hardening.

## High-level design
- `bin/hardhat`: CLI entrypoint, global flag parsing, command dispatch.
- `lib/`: shared helpers (logging, json, detection, validation, privilege, backup, confirmation).
- `modules/`: feature modules (`audit`, `firewall`, `ports`, `services`, `ssh_audit`, `updates`).
- `installers/`: install workflow for system-wide command availability.

## Runtime flow
1. User executes `hardhat`.
2. Entrypoint parses global options and command arguments.
3. Arch compatibility guard is enforced for operational commands.
4. Command is routed to its module implementation.
5. Module code performs collection, evaluation and rendering.

## Data flow model
- Checks produce notes and structured findings.
- Findings include `id`, `severity`, `title`, `description`, `recommendation`.
- Audit module derives overall score and severity.
- JSON rendering emits stable objects for automation.

## Safety model
- No silent system modifications.
- `--dry-run` simulates apply flow without touching system state.
- Backup precondition is mandatory before `firewall apply` changes.
- Global confirmation is required unless `--yes` is provided.
- Rollback automation is intentionally not implemented in MVP.

## Logging model
- Human-readable logs are emitted during execution.
- Firewall apply writes operational events to `/var/log/hardhat.log` when permissions allow.

## Known constraints
- Arch Linux only.
- UFW only firewall backend.
- Parsing is intentionally lightweight and degrades gracefully when output differs.
