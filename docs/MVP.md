# HardHat MVP Scope

## Goal
Build a stable and safe CLI baseline for Arch Linux security auditing and guided hardening.

## Included in MVP
- Arch Linux only.
- Modular Bash architecture.
- `hardhat` CLI command.
- Baseline audit flow with score/severity placeholders.
- Firewall checks and guided apply path scaffold (UFW only).
- Dry-run support.
- Global confirmation before apply.
- Backup helper as hard precondition for future config changes.
- Human and JSON output modes.

## Explicitly excluded for now
- Multi-distro support.
- nftables and iptables backends.
- Automatic rollback.
- Test suite in initial phase.