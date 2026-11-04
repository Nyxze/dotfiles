# Shared agent resources

The dotfiles checkout owns shared instructions, references, and personal skills.
Providers receive symlinks, so edits belong in this checkout. Other machine
configuration uses the repository's copied home layers.

| Resource | Open when |
| --- | --- |
| [Global instructions](knowledge/AGENTS.md) | Starting work or changing cross-project preferences. |
| [Knowledge index](knowledge/INDEX.md) | Finding the owner of a standing rule. |
| [Maintenance](knowledge/maintenance.md) | Adding, moving, or reviewing shared resources. |
| [Personal skills](skills/INDEX.md) | Selecting or maintaining a reusable workflow. |
| [Codex](providers/codex.md) | Checking Codex discovery and overrides. |
| [Claude Code](providers/claude-code.md) | Checking Claude instructions and skill discovery. |
| [OpenCode](providers/opencode.md) | Checking OpenCode discovery and compatibility paths. |

## Install and repair

Run from the repository root with Python 3 and PyYAML available (`python-yaml`
on Arch, `python3-yaml` on Mint). The [resource command](../scripts/agent-resources.py)
owns target selection and link behavior; `--help` lists options.

```bash
./scripts/agent-resources.py install --dry-run
./scripts/agent-resources.py install
./scripts/agent-resources.py install codex --only skills
./scripts/agent-resources.py check
```

No provider argument selects all three. Instruction installation also maintains
`~/AGENTS.md` as the canonical-source locator. Provider guides describe environment
overrides; use the same environment for installation, checking, and provider launch.

Installation validates sources and all selected destinations before writing.
Conflicting files or directories stop the operation. Inspect and reconcile them;
`--force` moves them to `$XDG_STATE_HOME/dotfiles/agent-backups/` (default
`~/.local/state/`) before linking. The command prints each backup path. Restore
by removing only the replacement symlink and moving the backup to its original
path. A dry run creates nothing.

Only stale skill symlinks pointing directly into this checkout's skill directory
are removed. Other skills, provider settings, and native agent definitions remain
provider-owned. Installation no longer copies or converts agent directories.

## Import a personal skill

```bash
./scripts/agent-resources.py capture claude-code --skill my-workflow
```

Capture requires one provider and explicit names. It copies a new skill from that
provider's skill directory after validating its manifest and resources. An existing
shared link is a successful no-op; divergent sources require a manual merge.
Capture never overwrites or deletes repository files. Add the new skill to the
skill index, validate it, then install. Edit existing personal skills in place.

## Verify

```bash
./scripts/validate-prompts.py
python3 -m unittest discover -s tests -p 'test_agent_*.py'
./scripts/agent-resources.py check
```

The validator checks local links, fragments, Claude imports, reachable documentation, entry
budgets, portable paths, and skill manifests. Tests exercise installation and
capture in temporary homes. `check` inspects live links and known instruction
shadowing; it does not prove model compliance or inspect every provider setting.
Use the native diagnostics in each provider guide for discovery checks.

With the provider CLIs installed, run the [native discovery probe](../scripts/check-agent-providers.py):

```bash
./scripts/check-agent-providers.py
./scripts/check-agent-providers.py codex
```

It checks skill catalogs without sending prompts or making model calls. Codex
and Claude use temporary configuration directories; OpenCode uses its live
configuration with external plugins disabled. This verifies discovery, not
model compliance or every plugin combination.

## Existing command names

`scripts/install.sh`, `scripts/install-skills.sh`, `prompts/link-knowledge.sh`, and
`prompts/link-skills.sh` delegate to the resource command. The skills-only menu
remains available. `prompts/capture.sh` now requires the explicit capture syntax
above; bulk agent capture and its destructive `--force` mode were removed.
