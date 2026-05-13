# HardHat MVP Scope

## Goal
Provide a stable first iteration of a security-focused Arch Linux CLI with useful baseline audit and controlled UFW apply flow.

## Implemented in current MVP
- Arch Linux guard for operational commands.
- Modular Bash project layout.
- Global CLI options: `--dry-run`, `--yes`, `--json`, `--verbose`, `--no-color`, `--help`, `--version`.
- Commands:
	- `hardhat audit` (+ JSON output)
	- `hardhat firewall audit` (+ JSON output)
	- `hardhat firewall apply` (with plan, backup precondition, confirmation and validation)
	- `hardhat menu` (stub)
- Baseline checks:
	- UFW status and defaults
	- Listening ports
	- Relevant running services
	- Basic SSH configuration signals
	- Pending updates as risk signal
- Structured findings with severity and recommendations.
- Score and summary generation for audit.
- Installer for system command deployment.

## Explicitly not implemented yet
- Multi-distro support.
- nftables/iptables backends.
- Automatic rollback.
- Interactive menu behavior.
- Dedicated uninstall command.
- Automated tests.
- Deep CVE scanning/integration with heavy scanners.

## Safety commitments in MVP
- No silent changes.
- `--dry-run` must avoid system modifications.
- If backup creation fails, `firewall apply` aborts.
- Global confirmation required for apply unless `--yes` is provided.