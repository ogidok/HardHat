# TODOs (Post-MVP baseline)

## Priority 1
- Implement real `menu` workflow.
- Improve SSH rule detection in `firewall apply` (less heuristic parsing).
- Improve post-apply validation (check expected rules, not only active/default).
- Add safer handling around interactive sudo/privileged command paths.

## Priority 2
- Add optional JSON output for `firewall apply` summary.
- Add command-specific help for all modules and subcommands.
- Normalize message catalog for fully consistent wording.
- Improve parser resilience for UFW output variations.

## Priority 3
- Add test strategy (shell unit tests and integration smoke tests).
- Add PKGBUILD for Arch packaging.
- Add dedicated uninstall command.
- Extend docs with troubleshooting and permission models.
